//
//  ShareRequestsView.swift
//  Quad-2025-project
//
//  Created by Isaac Choi on 9/22/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ShareRequestsView: View {
    @State private var requests: [ShareRequest] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(requests) { req in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("From:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(req.fromEmail)
                                .font(.subheadline)
                                .bold()
                        }
                        
                        HStack {
                            Text("Sent at:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(req.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                        }
                        
                        HStack {
                            Button("Accept") {
                                accept(req)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Decline") {
                                decline(req)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Shared Requests")
        }
    }

    
    private func loadRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("shares")
            .whereField("toUser", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, error in
                if let docs = snapshot?.documents {
                    var temp: [ShareRequest] = []
                    for doc in docs {
                        if var req = ShareRequest(id: doc.documentID, data: doc.data()) {
                            // lookup sharer email
                            db.collection("users").document(req.fromUser).getDocument { userSnap, _ in
                                if let email = userSnap?.data()?["email"] as? String {
                                    req.fromEmail = email
                                }
                            }
                            temp.append(req)
                        }
                    }
                    self.requests = temp
                }
            }
    }

    
    private func accept(_ req: ShareRequest) {
        db.collection("shares").document(req.id).updateData(["status": "accepted"])
    }
    
    private func decline(_ req: ShareRequest) {
        db.collection("shares").document(req.id).updateData(["status": "declined"])
    }
}

struct ShareRequest: Identifiable {
    var id: String
    var fromUser: String
    var fromEmail: String
    var toUser: String
    var eventId: String
    var createdAt: Date
    
    init?(id: String, data: [String: Any]) {
        guard let fromUser = data["fromUser"] as? String,
              let toUser = data["toUser"] as? String,
              let eventId = data["eventId"] as? String,
              let ts = data["createdAt"] as? Timestamp else {
            return nil
        }
        self.id = id
        self.fromUser = fromUser
        self.toUser = toUser
        self.eventId = eventId
        self.createdAt = ts.dateValue()
        
        // Default to UID for now, we’ll fetch email later
        self.fromEmail = fromUser
    }
}
