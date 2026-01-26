//
//  EventViewModel.swift
//  Quad-2025-project
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class EventViewModel: ObservableObject {

    // MARK: - Published
    @Published var events: [Event] = []

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var authListener: AuthStateDidChangeListenerHandle?

    // MARK: - User
    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Init
    init() {
        // 🔥 Auth 상태 변화에 따라 자동으로 리스닝 시작
        authListener = Auth.auth().addStateDidChangeListener { _, user in
            guard user != nil else {
                self.events = []
                self.listener?.remove()
                return
            }
            self.startListening()
        }
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
        listener?.remove()
    }

    // MARK: - Listen
    func startListening() {
        guard let uid else { return }
        listener?.remove()

        listener = db
            .collection("users")
            .document(uid)
            .collection("events")
            .order(by: "date")
            .addSnapshotListener { snap, err in
                if let err {
                    print("❌ Listen error:", err)
                    return
                }

                self.events = snap?.documents.compactMap {
                    try? $0.data(as: Event.self)
                } ?? []
            }
    }

    // MARK: - Add
    func addEvent(_ event: Event) {
        guard let uid else { return }

        do {
            var newEvent = event
            newEvent.ownerId = uid

            _ = try db
                .collection("users")
                .document(uid)
                .collection("events")
                .addDocument(from: newEvent)

            NotificationManager.shared.scheduleNotification(for: newEvent)
        } catch {
            print("❌ Error adding event:", error)
        }
    }

    // MARK: - Delete
    func deleteEvent(_ event: Event) {
        guard let uid, let id = event.id else { return }

        db.collection("users")
            .document(uid)
            .collection("events")
            .document(id)
            .delete()
    }

    // MARK: - Helpers
    func events(on date: Date) -> [Event] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.date, inSameDayAs: date) }
    }
    
    func updateEvent(
        eventId: String,
        title: String,
        date: Date,
        type: String,
        location: String,
        colorHex: String
    ) async throws {
        guard let uid else {
            throw NSError(domain: "Auth", code: 401)
        }

        try await db
            .collection("users")
            .document(uid)
            .collection("events")
            .document(eventId)
            .updateData([
                "title": title,
                "date": date,
                "type": type,
                "location": location,
                "colorHex": colorHex
            ])
    }
    
    func sendEventShareRequest(event: Event, to targetUID: String) async {
        print("🚨 SEND EVENT SHARE REQUEST:", event.id ?? "nil")
        guard let uid = uid, let eventId = event.id else { return }

        do {
            // 1️⃣ eventShareRequests 생성
            try await db
              .collection("eventShareRequests")
              .addDocument(data: [
                "eventId": eventId,
                "fromUid": uid,
                "toUid": targetUID,
                "status": "pending",
                "createdAt": Timestamp(),

                // 🔥 이벤트 스냅샷
                "event": [
                  "title": event.title,
                  "date": Timestamp(date: event.date),
                  "type": event.type,
                  "location": event.location,
                  "colorHex": event.colorHex
                ]
              ])


            // 2️⃣ 🔔 알림은 NotificationViewModel에게만 맡긴다
            let notificationVM = NotificationViewModel()
            notificationVM.sendEventInviteNotification(
                toUserId: targetUID,
                eventId: eventId,
                eventTitle: event.title
            )

            print("✅ Event share request + notification sent")

        } catch {
            print("❌ Failed to send event share request:", error)
        }
    }





}

