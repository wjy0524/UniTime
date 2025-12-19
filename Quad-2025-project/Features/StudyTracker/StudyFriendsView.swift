//
//  StudyFriendsView.swift
//  Quad-2025-project
//
//  View showing study friends using unified friends system
//

import FirebaseFirestore
import Kingfisher
import SwiftUI

struct StudyFriendsView: View {
    @ObservedObject private var friendsManager = FriendsManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var friendsStudyStatus: [String: FriendStudyStatus] = [:]

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    headerStats

                    // Friends List
                    if friendsManager.friends.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(friendsManager.friends) { friend in
                                FriendStudyCardWithStatus(
                                    friend: friend,
                                    status: friendsStudyStatus[friend.friendId],
                                    colorScheme: colorScheme
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Study Friends")
            .onAppear {
                friendsManager.startListening()
                // Delay to let friends load first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startListeningToFriendsStatus()
                }
            }
        }
    }

    // MARK: - Listen to Friends Study Status

    func startListeningToFriendsStatus() {
        print("🔊 Starting to listen to \(friendsManager.friends.count) friends' study status")

        for friend in friendsManager.friends {
            print("👂 Listening to friend: \(friend.friendUsername) (\(friend.friendId))")
            listenToFriendStatus(friendId: friend.friendId, username: friend.friendUsername)
        }
    }

    func listenToFriendStatus(friendId: String, username: String) {
        db.collection("studySessions")
            .whereField("userId", isEqualTo: friendId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening to friend \(username) status: \(error)")
                    return
                }

                print("📡 Snapshot received for \(username)")
                print("   Documents count: \(snapshot?.documents.count ?? 0)")

                if let documents = snapshot?.documents, !documents.isEmpty {
                    // Friend is studying
                    print("✅ \(username) is STUDYING")
                    if let session = try? documents.first?.data(as: StudySession.self) {
                        let elapsed = Date().timeIntervalSince(session.startTime)
                        print("   Session started: \(session.startTime)")
                        print("   Elapsed: \(elapsed) seconds")

                        DispatchQueue.main.async {
                            self.friendsStudyStatus[friendId] = FriendStudyStatus(
                                id: friendId,
                                userId: friendId,
                                username: username,
                                isStudying: true,
                                currentSessionId: session.id,
                                sessionStartTime: session.startTime,
                                elapsedTime: elapsed,
                                todayTotalTime: 0,
                                weekTotalTime: 0,
                                lastUpdated: Date()
                            )
                        }
                    }
                } else {
                    // Friend is not studying
                    print("⏸️ \(username) is NOT studying")
                    DispatchQueue.main.async {
                        self.friendsStudyStatus[friendId] = FriendStudyStatus(
                            id: friendId,
                            userId: friendId,
                            username: username,
                            isStudying: false,
                            currentSessionId: nil,
                            sessionStartTime: nil,
                            elapsedTime: 0,
                            todayTotalTime: 0,
                            weekTotalTime: 0,
                            lastUpdated: Date()
                        )
                    }
                }
            }
    }

    // MARK: - Header Stats

    var headerStats: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("\(friendsManager.friends.count)")
                    .font(.title)
                    .bold()

                Text("Friends")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5))
            .cornerRadius(12)
        }
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Study Friends")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Add friends from the main Friends page to see them here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Friend Study Card With Status

struct FriendStudyCardWithStatus: View {
    let friend: Friend
    let status: FriendStudyStatus?
    var colorScheme: ColorScheme
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile Image
                if let imageURL = friend.friendProfileImage, !imageURL.isEmpty,
                    let url = URL(string: imageURL)
                {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            status?.isStudying == true
                                ? Circle()
                                    .stroke(Color.orange, lineWidth: 3)
                                : nil
                        )
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                        .overlay(
                            status?.isStudying == true
                                ? Circle()
                                    .stroke(Color.orange, lineWidth: 3)
                                : nil
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.friendUsername)
                        .font(.headline)

                    if status?.isStudying == true {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Studying now")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                            Text("Not studying")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                if status?.isStudying == true {
                    Image(systemName: "book.fill")
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "book.closed")
                        .foregroundColor(.secondary)
                }
            }

            // Show timer if studying
            if let status = status, status.isStudying, let startTime = status.sessionStartTime {
                let elapsed = currentTime.timeIntervalSince(startTime)
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)

                    Text("Current: ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(formatElapsedTime(elapsed))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .monospacedDigit()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .onReceive(timer) { _ in
                    currentTime = Date()
                }
            }
        }
        .padding()
        .background(
            status?.isStudying == true
                ? Color.orange.opacity(0.05)
                : Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    status?.isStudying == true ? Color.orange : Color.clear,
                    lineWidth: status?.isStudying == true ? 2 : 0
                )
        )
        .cornerRadius(12)
    }

    func formatElapsedTime(_ elapsed: TimeInterval) -> String {
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) % 3600 / 60
        let seconds = Int(elapsed) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
