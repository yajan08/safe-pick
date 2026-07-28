const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggers when a student document is updated.
 * Checks if the 'current_status' changed, and if so, sends an FCM notification to the parent.
 */
exports.onStudentStatusChanged = onDocumentUpdated("students/{studentId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) return;

    const oldStatus = beforeData.current_status;
    const newStatus = afterData.current_status;

    // Only proceed if the status actually changed
    if (oldStatus === newStatus) return;

    const parentUid = afterData.parent_uid;
    if (!parentUid) {
        console.log("No parent_uid found for student:", event.params.studentId);
        return;
    }

    // Fetch the parent's user document to get the FCM token
    const parentDoc = await admin.firestore().collection("users").doc(parentUid).get();
    if (!parentDoc.exists) {
        console.log("Parent document not found for uid:", parentUid);
        return;
    }

    const fcmToken = parentDoc.data().fcmToken;
    if (!fcmToken) {
        console.log("No FCM token found for parent:", parentUid);
        return;
    }

    const studentName = afterData.name || "Your child";
    
    // Construct the message payload
    const message = {
        token: fcmToken,
        notification: {
            title: `SafePick: Status Update`,
            body: `${studentName} is now ${newStatus}.`,
        },
        data: {
            studentId: event.params.studentId,
            newStatus: newStatus,
        },
    };

    try {
        await admin.messaging().send(message);
        console.log(`Successfully sent status update notification to ${parentUid}`);
    } catch (error) {
        console.error("Error sending FCM notification:", error);
    }
});

/**
 * Triggers when a new daily session (trip) is started.
 * Sends a notification to all parents whose children are on this trip manifest.
 */
exports.onTripStarted = onDocumentCreated("daily_sessions/{sessionId}", async (event) => {
    const sessionData = event.data.data();
    if (!sessionData) return;

    const tripId = sessionData.trip_id;
    if (!tripId) return;

    // Fetch the trip manifest to get all students
    const manifestSnapshot = await admin.firestore().collection("trips").doc(tripId).collection("trip_manifest").get();
    
    if (manifestSnapshot.empty) {
        console.log("Manifest is empty for trip:", tripId);
        return;
    }

    const parentTokens = new Set();

    // Iterate through students, fetch their parent_uid, and then the parent's FCM token
    for (const doc of manifestSnapshot.docs) {
        const studentId = doc.id;
        const studentDoc = await admin.firestore().collection("students").doc(studentId).get();
        
        if (studentDoc.exists) {
            const parentUid = studentDoc.data().parent_uid;
            if (parentUid) {
                const parentDoc = await admin.firestore().collection("users").doc(parentUid).get();
                if (parentDoc.exists) {
                    const fcmToken = parentDoc.data().fcmToken;
                    if (fcmToken) {
                        parentTokens.add(fcmToken);
                    }
                }
            }
        }
    }

    if (parentTokens.size === 0) {
        console.log("No parent tokens found for trip:", tripId);
        return;
    }

    // Construct the multicast message payload
    const message = {
        tokens: Array.from(parentTokens),
        notification: {
            title: `SafePick: Trip Started!`,
            body: `The van is on its way. Track it live in the app.`,
        },
        data: {
            tripId: tripId,
            sessionId: event.params.sessionId,
        },
    };

    try {
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Trip started notification sent. Successes: ${response.successCount}, Failures: ${response.failureCount}`);
    } catch (error) {
        console.error("Error sending multicast FCM notification:", error);
    }
});

/**
 * Scheduled function to check for students who are "In Van" and send a notification
 * when they are approximately 10 minutes away.
 */
exports.checkApproachingStudents = onSchedule("every 2 minutes", async (event) => {
    // We get all students currently "In Van"
    const studentsSnapshot = await admin.firestore().collection("students")
        .where("current_status", "==", "In Van")
        .where("eta_notified", "==", false)
        .get();

    if (studentsSnapshot.empty) return;

    const now = Date.now();
    const isMorning = new Date().getHours() < 12; // Approximation, fast calculation

    for (const doc of studentsSnapshot.docs) {
        const studentData = doc.data();
        if (!studentData.in_van_since || !studentData.stats) continue;

        const inVanSince = studentData.in_van_since.toDate().getTime();
        
        let avgDurationMs = 0;
        let count = 0;

        if (isMorning) {
            count = studentData.stats.morning_trip_count || 0;
            avgDurationMs = studentData.stats.morning_avg_duration_ms || 0;
        } else {
            count = studentData.stats.afternoon_trip_count || 0;
            avgDurationMs = studentData.stats.afternoon_avg_duration_ms || 0;
        }

        // Only send if we have enough historical data
        if (count >= 10 && avgDurationMs > 0) {
            const timeInVanMs = now - inVanSince;
            const remainingMs = avgDurationMs - timeInVanMs;

            // If remaining time is less than or equal to 12 minutes (720000ms), send the warning.
            // We use 12 mins to safely catch the "around 10 mins" window since this runs every 2 mins.
            if (remainingMs <= 720000 && remainingMs > 0) {
                // Fetch parent to get FCM token
                const parentUid = studentData.parent_uid;
                if (!parentUid) continue;

                const parentDoc = await admin.firestore().collection("users").doc(parentUid).get();
                if (!parentDoc.exists) continue;

                const fcmToken = parentDoc.data().fcmToken;
                if (!fcmToken) continue;

                const studentName = studentData.name || "Your child";
                const message = {
                    token: fcmToken,
                    notification: {
                        title: `SafePick: Arriving Soon`,
                        body: `${studentName} is approximately 10 minutes away!`,
                    },
                    data: {
                        studentId: doc.id,
                        type: "ETA_WARNING",
                    },
                };

                try {
                    await admin.messaging().send(message);
                    // Mark as notified
                    await doc.ref.update({ eta_notified: true });
                    console.log(`Sent 10-min warning for ${studentName} to ${parentUid}`);
                } catch (error) {
                    console.error("Error sending ETA warning:", error);
                }
            }
        }
    }
});

/**
 * Triggers when a student's attendance document is updated in a daily session.
 * Sends FCM notifications when the van enters approaching (500m) or arrived (50m) geofences.
 */
exports.onGeofenceNotificationTriggered = onDocumentUpdated("daily_sessions/{sessionId}/attendance/{studentId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) return;

    const studentId = event.params.studentId;

    // Check approaching_notified transition
    const wasApproaching = beforeData.approaching_notified === true;
    const isApproaching = afterData.approaching_notified === true;

    // Check arrived_notified transition
    const wasArrived = beforeData.arrived_notified === true;
    const isArrived = afterData.arrived_notified === true;

    if (!wasApproaching && isApproaching) {
        await sendGeofenceNotification(studentId, "Approaching", "is approaching your location (within 500 meters).");
    }

    if (!wasArrived && isArrived) {
        await sendGeofenceNotification(studentId, "Arrived", "has arrived at your location. Please proceed to the van.");
    }
});

/**
 * Helper to retrieve parent's FCM token and dispatch notification
 */
async function sendGeofenceNotification(studentId, type, messageBody) {
    try {
        const studentDoc = await admin.firestore().collection("students").doc(studentId).get();
        if (!studentDoc.exists) {
            console.log("Student document not found for id:", studentId);
            return;
        }

        const studentData = studentDoc.data();
        const parentUid = studentData.parent_uid;
        if (!parentUid) {
            console.log("No parent_uid found for student:", studentId);
            return;
        }

        const parentDoc = await admin.firestore().collection("users").doc(parentUid).get();
        if (!parentDoc.exists) {
            console.log("Parent user document not found for uid:", parentUid);
            return;
        }

        const fcmToken = parentDoc.data().fcmToken;
        if (!fcmToken) {
            console.log("No FCM token found for parent user:", parentUid);
            return;
        }

        const studentName = studentData.name || "Your child";
        const title = type === "Approaching" ? `SafePick: Van Approaching` : `SafePick: Van Arrived`;
        const body = `${studentName} ${messageBody}`;

        const payload = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: {
                studentId: studentId,
                type: `GEOFENCE_${type.toUpperCase()}`,
            },
        };

        await admin.messaging().send(payload);
        console.log(`Successfully sent ${type} notification to parent ${parentUid} for student ${studentId}`);
    } catch (error) {
        console.error(`Error sending ${type} geofence notification:`, error);
    }
}

