/**
 * Local Test Script for SafePick Cloud Functions Notifications
 * 
 * This script runs locally using Node.js. It mocks firebase-admin and firebase-functions
 * modules in the Node.js require cache before loading index.js, enabling us to
 * test our functions without any real Firebase connection.
 */

// 1. Mock firebase-admin
const mockDocs = {};

const createDocMock = (path) => ({
    get: async () => {
        const data = mockDocs[path] || null;
        return {
            exists: data !== null,
            id: path.split("/").pop(),
            ref: createDocMock(path),
            data: () => data,
        };
    },
    update: async (updates) => {
        mockDocs[path] = { ...mockDocs[path], ...updates };
        console.log(`   💾 [FIRESTORE UPDATE] ${path}:`, JSON.stringify(updates));
    },
    set: async (data, options) => {
        if (options && options.merge) {
            mockDocs[path] = { ...mockDocs[path], ...data };
        } else {
            mockDocs[path] = data;
        }
        console.log(`   💾 [FIRESTORE SET] ${path}:`, JSON.stringify(data));
    },
    collection: (subName) => createCollectionMock(`${path}/${subName}`),
});

const createCollectionMock = (colPath) => {
    const chain = {
        doc: (docId) => createDocMock(`${colPath}/${docId}`),
        where: () => chain,
        get: async () => {
            const docs = [];
            const prefix = `${colPath}/`;
            for (const key of Object.keys(mockDocs)) {
                if (key.startsWith(prefix)) {
                    const rest = key.substring(prefix.length);
                    if (!rest.includes("/")) {
                        docs.push({
                            id: rest,
                            ref: createDocMock(key),
                            data: () => mockDocs[key],
                        });
                    }
                }
            }
            return {
                empty: docs.length === 0,
                docs: docs,
            };
        }
    };
    return chain;
};

const messagingMock = {
    send: async (payload) => {
        console.log(`   📨 [FCM SEND] Single Message:`);
        console.log(`      Token: ${payload.token}`);
        console.log(`      Title: "${payload.notification.title}"`);
        console.log(`      Body:  "${payload.notification.body}"`);
        console.log(`      Data:  `, payload.data);
        return "mock_msg_id";
    },
    sendEachForMulticast: async (payload) => {
        console.log(`   📨 [FCM SEND] Multicast Message:`);
        console.log(`      Tokens:`, payload.tokens);
        console.log(`      Title:  "${payload.notification.title}"`);
        console.log(`      Body:   "${payload.notification.body}"`);
        console.log(`      Data:   `, payload.data);
        return { successCount: payload.tokens.length, failureCount: 0 };
    }
};

const mockAdmin = {
    initializeApp: () => {},
    firestore: () => ({
        collection: (colName) => createCollectionMock(colName)
    }),
    messaging: () => messagingMock
};

// Add Timestamp helper
mockAdmin.firestore.Timestamp = {
    now: () => ({
        toDate: () => new Date()
    }),
    fromDate: (date) => ({
        toDate: () => date
    })
};

// Put mock admin in Node.js require cache
const adminPath = require.resolve('firebase-admin');
require.cache[adminPath] = {
    id: adminPath,
    filename: adminPath,
    loaded: true,
    exports: mockAdmin
};

// 2. Mock firebase-functions v2 provider wrappers in cache
const firestoreV2 = {
    onDocumentUpdated: (path, handler) => handler,
    onDocumentCreated: (path, handler) => handler,
};
const firestoreV2Path = require.resolve('firebase-functions/v2/firestore');
require.cache[firestoreV2Path] = {
    id: firestoreV2Path,
    filename: firestoreV2Path,
    loaded: true,
    exports: firestoreV2
};

const schedulerV2 = {
    onSchedule: (schedule, handler) => handler,
};
const schedulerV2Path = require.resolve('firebase-functions/v2/scheduler');
require.cache[schedulerV2Path] = {
    id: schedulerV2Path,
    filename: schedulerV2Path,
    loaded: true,
    exports: schedulerV2
};

// 3. Now load index.js (it will consume our mocked modules)
const myFunctions = require("./index.js");

// Setup helper for initial mock data
function setupMockDatabase() {
    // Clear old docs
    for (const key of Object.keys(mockDocs)) {
        delete mockDocs[key];
    }

    // Mock Parent User
    mockDocs["users/parent_123"] = {
        name: "John Doe",
        role: "Parent",
        fcmToken: "parent_fcm_token_xyz"
    };

    // Mock Student
    mockDocs["students/student_123"] = {
        name: "Alice Doe",
        parent_uid: "parent_123",
        current_status: "At Home",
        in_van_since: mockAdmin.firestore.Timestamp.now(),
        stats: {
            morning_trip_count: 15,
            morning_avg_duration_ms: 1200000, // 20 minutes
            afternoon_trip_count: 15,
            afternoon_avg_duration_ms: 1200000 // 20 minutes
        },
        eta_notified: false
    };

    // Mock Trip Manifest entry
    mockDocs["trips/trip_999/trip_manifest/student_123"] = {
        stop_order: 1,
        status: "At Home"
    };
}

// Verification Tests
async function runTests() {
    console.log("=== STARTING CLOUD FUNCTIONS NOTIFICATION TESTS ===\n");
    
    // ----------------------------------------------------
    // TEST 1: onStudentStatusChanged
    // ----------------------------------------------------
    console.log("--- Test 1: Triggering onStudentStatusChanged (Status: At Home -> In Van) ---");
    setupMockDatabase();
    
    const statusChangedEvent = {
        params: { studentId: "student_123" },
        data: {
            before: {
                data: () => ({ ...mockDocs["students/student_123"], current_status: "At Home" })
            },
            after: {
                data: () => ({ ...mockDocs["students/student_123"], current_status: "In Van" })
            }
        }
    };
    await myFunctions.onStudentStatusChanged(statusChangedEvent);
    console.log("\n");

    // ----------------------------------------------------
    // TEST 2: onTripStarted
    // ----------------------------------------------------
    console.log("--- Test 2: Triggering onTripStarted ---");
    setupMockDatabase();
    
    const tripStartedEvent = {
        params: { sessionId: "session_abc" },
        data: {
            data: () => ({
                trip_id: "trip_999",
                driver_uid: "driver_888",
                status: "in_progress"
            })
        }
    };
    await myFunctions.onTripStarted(tripStartedEvent);
    console.log("\n");

    // ----------------------------------------------------
    // TEST 3: onGeofenceNotificationTriggered (Approaching)
    // ----------------------------------------------------
    console.log("--- Test 3: Triggering onGeofenceNotificationTriggered (Approaching) ---");
    setupMockDatabase();
    
    const geofenceApproachingEvent = {
        params: { sessionId: "session_abc", studentId: "student_123" },
        data: {
            before: {
                data: () => ({ status: "At Home", approaching_notified: false, arrived_notified: false })
            },
            after: {
                data: () => ({ status: "At Home", approaching_notified: true, arrived_notified: false })
            }
        }
    };
    await myFunctions.onGeofenceNotificationTriggered(geofenceApproachingEvent);
    console.log("\n");

    // ----------------------------------------------------
    // TEST 4: onGeofenceNotificationTriggered (Arrived)
    // ----------------------------------------------------
    console.log("--- Test 4: Triggering onGeofenceNotificationTriggered (Arrived) ---");
    setupMockDatabase();
    
    const geofenceArrivedEvent = {
        params: { sessionId: "session_abc", studentId: "student_123" },
        data: {
            before: {
                data: () => ({ status: "At Home", approaching_notified: true, arrived_notified: false })
            },
            after: {
                data: () => ({ status: "At Home", approaching_notified: true, arrived_notified: true })
            }
        }
    };
    await myFunctions.onGeofenceNotificationTriggered(geofenceArrivedEvent);
    console.log("\n");

    // ----------------------------------------------------
    // TEST 5: checkApproachingStudents (Scheduled ETA alert)
    // ----------------------------------------------------
    console.log("--- Test 5: Triggering checkApproachingStudents (Scheduled ETA alert) ---");
    setupMockDatabase();
    
    // Set mock student in the van for a while (say, 10 minutes ago, where avg duration is 20m)
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    mockDocs["students/student_123"].current_status = "In Van";
    mockDocs["students/student_123"].in_van_since = {
        toDate: () => tenMinutesAgo
    };
    
    await myFunctions.checkApproachingStudents({});
    console.log("\n");

    console.log("=== ALL TESTS COMPLETED ===");
}

runTests().catch(err => {
    console.error("Test execution failed:", err);
});
