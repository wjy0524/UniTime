//
//  NotificationService.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/25/26.
//

import FirebaseAuth
import FirebaseFirestore

struct NotificationService {
    static func sendEventInvite(
        toUserId: String,
        eventId: String,
        eventTitle: String
    ) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        db.collection("users").document(currentUserId).getDocument { snapshot, _ in
            guard
                let data = snapshot?.data(),
                let username = data["username"] as? String
            else { return }

            db.collection("notifications").addDocument(data: [
                "type": "event_invite",
                "fromUserId": currentUserId,
                "fromUsername": username,
                "toUserId": toUserId,
                "message": "\(username) shared an event: \(eventTitle)",
                "eventId": eventId,
                "timestamp": Timestamp(),
                "isRead": false
            ])
        }
    }
}
