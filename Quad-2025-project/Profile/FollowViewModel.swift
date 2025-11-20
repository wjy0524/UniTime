//
//  FollowViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/19/25.
//

//
//  FollowViewModel.swift
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FollowViewModel: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var followers: [String] = []
    @Published var following: [String] = []
    
    var myUid: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    // MARK: - Follow
    func follow(targetUid: String) async {
        guard myUid != targetUid else { return }
        
        do {
            try await db.collection("users")
                .document(myUid)
                .collection("following")
                .document(targetUid)
                .setData([
                    "uid": targetUid,
                    "timestamp": FieldValue.serverTimestamp()
                ])
            
            try await db.collection("users")
                .document(targetUid)
                .collection("followers")
                .document(myUid)
                .setData([
                    "uid": myUid,
                    "timestamp": FieldValue.serverTimestamp()
                ])
            
        } catch {
            print("❌ Follow error:", error)
        }
    }
    
    // MARK: - Unfollow
    func unfollow(targetUid: String) async {
        do {
            try await db.collection("users")
                .document(myUid)
                .collection("following")
                .document(targetUid)
                .delete()
            
            try await db.collection("users")
                .document(targetUid)
                .collection("followers")
                .document(myUid)
                .delete()
            
        } catch {
            print("❌ Unfollow error:", error)
        }
    }
    
    // MARK: - Load my following list
    func loadFollowing() async {
        do {
            let snap = try await db.collection("users")
                .document(myUid)
                .collection("following")
                .getDocuments()
            
            self.following = snap.documents.map { $0.documentID }
        } catch {
            print("❌ loadFollowing error:", error)
        }
    }
    
    // MARK: - Load my followers
    func loadFollowers() async {
        do {
            let snap = try await db.collection("users")
                .document(myUid)
                .collection("followers")
                .getDocuments()
            
            self.followers = snap.documents.map { $0.documentID }
        } catch {
            print("❌ loadFollowers error:", error)
        }
    }

    // MARK: - Load following for ANY user
    func loadFollowing(of uid: String) async -> [String] {
        do {
            let snap = try await db.collection("users")
                .document(uid)
                .collection("following")
                .getDocuments()
            
            return snap.documents.map { $0.documentID }
        } catch {
            print("❌ loadFollowing(of:) error:", error)
            return []
        }
    }
    
    func loadFollowingUsers(of uid: String) async -> [UserMini] {
        do {
            let snap = try await db.collection("users")
                .document(uid)
                .collection("following")
                .getDocuments()

            let uids = snap.documents.map { $0.documentID }
            if uids.isEmpty { return [] }

            // Firestore users 컬렉션에서 해당 uid들만 가져오기
            let userSnap = try await db.collection("users")
                .whereField("uid", in: uids)
                .getDocuments()

            return userSnap.documents.compactMap { doc in
                let data = doc.data()
                guard
                    let username = data["username"] as? String,
                    let profileImageURL = data["profileImageURL"] as? String,
                    let uid = data["uid"] as? String
                else { return nil }

                return UserMini(uid: uid, username: username, profileImageURL: profileImageURL)
            }

        } catch {
            print("❌ loadFollowingUsers error:", error)
            return []
        }
    }


}

