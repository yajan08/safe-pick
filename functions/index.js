const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
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
