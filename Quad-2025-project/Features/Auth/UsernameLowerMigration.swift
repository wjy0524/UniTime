//
//  UsernameLowerMigration.swift
//  Quad-2025-project
//
//  Created on Username Lower Migration Utility
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class UsernameLowerMigration {

    private let db = Firestore.firestore()

    // MARK: - Migrate Current User
    func migrateCurrentUser(completion: ((Bool) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in")
            completion?(false)
            return
        }

        let userRef = db.collection("users").document(userId)

        userRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Migration error: \(error.localizedDescription)")
                completion?(false)
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                print("⚠️ User document has no username field")
                completion?(false)
                return
            }

            if data["username_lower"] != nil {
                print("✅ username_lower already exists for: \(username)")
                completion?(true)
                return
            }

            userRef.updateData([
                "username_lower": username.lowercased()
            ]) { error in
                if let error = error {
                    print("❌ Failed to add username_lower: \(error.localizedDescription)")
                    completion?(false)
                } else {
                    print("✅ Added username_lower: \(username) -> \(username.lowercased())")
                    completion?(true)
                }
            }
        }
    }

    func migrateAllUsers(completion: @escaping (Int, Int) -> Void) {
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Failed to fetch users: \(error.localizedDescription)")
                completion(0, 0)
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No users found")
                completion(0, 0)
                return
            }

            print("📊 Found \(documents.count) users")

            let batch = self.db.batch()
            var updateCount = 0

            for doc in documents {
                let data = doc.data()

                if let username = data["username"] as? String,
                    data["username_lower"] == nil
                {
                    batch.updateData(
                        [
                            "username_lower": username.lowercased()
                        ], forDocument: doc.reference)

                    updateCount += 1
                    print("📝 Queued update: \(username) -> \(username.lowercased())")
                }
            }

            if updateCount > 0 {
                batch.commit { error in
                    if let error = error {
                        print("❌ Batch update failed: \(error.localizedDescription)")
                        completion(0, documents.count)
                    } else {
                        print(
                            "✅ Migration complete! Updated \(updateCount) of \(documents.count) users"
                        )
                        completion(updateCount, documents.count)
                    }
                }
            } else {
                print("✅ No users need migration")
                completion(0, documents.count)
            }
        }
    }

    // MARK: - Verification

    func verifyCurrentUser(completion: @escaping (Bool, String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, "No user logged in")
            return
        }

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(false, "Error: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                completion(false, "No username found")
                return
            }

            if let usernameLower = data["username_lower"] as? String {
                let isCorrect = usernameLower == username.lowercased()
                if isCorrect {
                    completion(true, "✅ username_lower is correct: \(usernameLower)")
                } else {
                    completion(
                        false,
                        "⚠️ username_lower is incorrect: \(usernameLower) should be \(username.lowercased())"
                    )
                }
            } else {
                completion(false, "❌ username_lower field is missing")
            }
        }
    }

    // MARK: - Test Search

    func testSearch(query: String, completion: @escaping ([String]) -> Void) {
        let searchText = query.lowercased()

        db.collection("users")
            .whereField("username_lower", isGreaterThanOrEqualTo: searchText)
            .whereField("username_lower", isLessThanOrEqualTo: searchText + "~")
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Search error: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let usernames =
                    snapshot?.documents.compactMap { doc in
                        doc.data()["username"] as? String
                    } ?? []

                print("🔍 Search '\(query)' found \(usernames.count) results: \(usernames)")
                completion(usernames)
            }
    }
}

struct UsernameLowerMigrationModifier: ViewModifier {
    @State private var hasMigrated = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasMigrated {
                    UsernameLowerMigration().migrateCurrentUser { success in
                        hasMigrated = true
                    }
                }
            }
    }
}

extension View {
    func migrateUsernameLower() -> some View {
        modifier(UsernameLowerMigrationModifier())
    }
}
