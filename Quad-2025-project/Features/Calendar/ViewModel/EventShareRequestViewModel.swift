//
//  EventShareRequestViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 1/25/26.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class EventShareRequestViewModel: ObservableObject {
    @Published var requests: [EventShareRequest] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var uid: String? { Auth.auth().currentUser?.uid }

    deinit { listener?.remove() }

    // 🔔 내가 받은 pending 요청만 듣기
    func startListening() {
        guard let uid else { return }
        listener?.remove()

        listener = db.collection("eventShareRequests")
            .whereField("toUid", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snap, err in
                if let err {
                    print("❌ request listen error:", err)
                    return
                }
                self.requests = snap?.documents.compactMap {
                    try? $0.data(as: EventShareRequest.self)
                } ?? []
            }
    }

    // ✅ 수락: 원본 이벤트를 내 캘린더로 복제
    func accept(requestId: String) async {
        print("🚨🚨🚨 ACCEPT CALLED:", requestId)
        guard let myUid = uid else { return }

        let reqRef = db.collection("eventShareRequests").document(requestId)
        let eventsRef = db
            .collection("users")
            .document(myUid)
            .collection("events")

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                db.runTransaction({ (transaction, errorPointer) -> Any? in
                    do {
                        let snap = try transaction.getDocument(reqRef)

                        guard
                            let status = snap.get("status") as? String,
                            status == "pending"
                        else {
                            errorPointer?.pointee = NSError(domain: "AlreadyProcessed", code: 409)
                            return nil
                        }

                        transaction.updateData(
                            ["status": "accepted"],
                            forDocument: reqRef
                        )

                        guard
                            let eventData = snap.get("event") as? [String: Any],
                            let title = eventData["title"] as? String,
                            let timestamp = eventData["date"] as? Timestamp,
                            let type = eventData["type"] as? String,
                            let location = eventData["location"] as? String,
                            let colorHex = eventData["colorHex"] as? String
                        else {
                            errorPointer?.pointee = NSError(domain: "InvalidEventSnapshot", code: 400)
                            return nil
                        }

                        let newEvent = Event(
                            ownerId: myUid,
                            title: title,
                            date: timestamp.dateValue(),
                            type: type,
                            location: location,
                            colorHex: colorHex,
                            sharedWith: []
                        )

                        let newDoc = eventsRef.document()
                        try transaction.setData(from: newEvent, forDocument: newDoc)

                        return nil
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            print("❌ accept failed:", error)
        }
    }







    func decline(requestId: String) async {
        print("❄️ DECLINE CALLED:", requestId)
        let reqRef = db.collection("eventShareRequests").document(requestId)

        do {
            let snap = try await reqRef.getDocument()
            guard snap.exists,
                  snap.get("status") as? String == "pending"
            else { return }

            try await reqRef.updateData(["status": "declined"])
        } catch {
            print("❌ decline failed:", error)
        }
    }


}
