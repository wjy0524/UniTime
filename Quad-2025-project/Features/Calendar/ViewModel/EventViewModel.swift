//
//  EventViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    deinit { listener?.remove() }

    func startListening() {
        guard let uid else { return }
        listener?.remove()

        listener = db.collection("events")
            .whereFilter(
                .orFilter([
                    .whereField("ownerId", isEqualTo: uid),
                    .whereField("sharedWith", arrayContains: uid),
                ])
            )
            .order(by: "date")
            .addSnapshotListener { snap, err in
                if let docs = snap?.documents {
                    self.events = docs.compactMap { try? $0.data(as: Event.self) }
                }
            }
    }

    func addEvent(_ event: Event) {
        guard let uid else { return }
        do {
            var newEvent = event
            newEvent.ownerId = uid

            _ = try db.collection("events").addDocument(from: newEvent)

            NotificationManager.shared.scheduleNotification(for: newEvent)
        } catch {
            print("❌ Error adding event:", error)
        }
    }

    func deleteEvent(_ event: Event) {
        guard let id = event.id else { return }
        db.collection("events").document(id).delete()
    }

    func shareEvent(_ event: Event, to targetUID: String) async {
        guard let id = event.id else { return }

        do {
            try await db.collection("events").document(id).updateData([
                "sharedWith": FieldValue.arrayUnion([targetUID])
            ])
        } catch {
            print("❌ Sharing error:", error)
        }
    }

    func events(on date: Date) -> [Event] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.date, inSameDayAs: date) }
    }
}
