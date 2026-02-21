//
//  DecisionEngine.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/20/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum HeroCardType: Identifiable {
    case bestTime(friends: [String], time: String, day: String)
    case dining(hall: String, status: String)
    case gradeScenario(course: String, requirement: String)
    case studyNow(todayMinutes: Int, weeklyGoal: Int)
    case addFriends
    case shareSchedule
    
    var id: String {
        switch self {
        case .bestTime: return "bestTime"
        case .dining: return "dining"
        case .gradeScenario: return "gradeScenario"
        case .studyNow: return "studyNow"
        case .addFriends: return "addFriends"
        case .shareSchedule: return "shareSchedule"
        }
    }
}

@MainActor
class DecisionEngine: ObservableObject {
    
    @Published var heroCard: HeroCardType?
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Compute Hero Card
    
    func computeHeroCard() async {
        guard let userId = currentUserId else {
            heroCard = .addFriends
            return
        }
        
        isLoading = true
        
        // 1️⃣ Check for friend overlap (최우선)
        if let overlap = await checkFriendOverlap(userId) {
            heroCard = overlap
            isLoading = false
            return
        }
        
        // 2️⃣ Check dining time
        if let dining = checkDiningTime() {
            heroCard = dining
            isLoading = false
            return
        }
        
        // 3️⃣ Check grade scenario
        if let grade = await checkGradeScenario(userId) {
            heroCard = grade
            isLoading = false
            return
        }
        
        // 4️⃣ Check study progress
        if let study = await checkStudyProgress(userId) {
            heroCard = study
            isLoading = false
            return
        }
        
        // 5️⃣ Check if user has friends
        let friendsExist = await hasFriends(userId)
        if !friendsExist {
            heroCard = .addFriends
            isLoading = false
            return
        }
        
        // 6️⃣ Check if schedule shared
        let hasShared = await hasSharedSchedule(userId)
        if !hasShared {
            heroCard = .shareSchedule
            isLoading = false
            return
        }
        
        // 7️⃣ Default: Add friends
        heroCard = .addFriends
        isLoading = false
    }
    
    // MARK: - Check Functions
    
    private func checkFriendOverlap(_ userId: String) async -> HeroCardType? {
        do {
            // 1. 내 시간표 가져오기
            let myScheduleDoc = try await db
                .collection("users")
                .document(userId)
                .collection("timetable")
                .getDocuments()
            
            guard !myScheduleDoc.documents.isEmpty else { return nil }
            
            // 2. 친구 목록 가져오기
            let friendsDoc = try await db
                .collection("users")
                .document(userId)
                .collection("friends")
                .getDocuments()
            
            guard !friendsDoc.documents.isEmpty else { return nil }
            
            // 3. 공유된 시간표가 있는 친구들 찾기
            let acceptedRequests = try await db
                .collection("timetableShareRequests")
                .whereField("toUserId", isEqualTo: userId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()
            
            guard !acceptedRequests.documents.isEmpty else { return nil }
            
            // 4. 다음 48시간 내 겹치는 시간 찾기
            // (간단한 버전: 목요일 1-3pm 하드코딩)
            let friendNames = friendsDoc.documents.compactMap {
                $0.data()["username"] as? String
            }
            
            if !friendNames.isEmpty {
                return .bestTime(
                    friends: Array(friendNames.prefix(2)),
                    time: "1–3 PM",
                    day: "Thursday"
                )
            }
            
            return nil
            
        } catch {
            print("❌ Error checking overlap: \(error)")
            return nil
        }
    }
    
    private func checkDiningTime() -> HeroCardType? {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        // 주말 제외
        guard weekday >= 2 && weekday <= 6 else { return nil }
        
        // Lunch: 11am - 2pm
        if hour >= 11 && hour < 14 {
            return .dining(
                hall: "Kins Dining",
                status: "Open · Not busy 🟢"
            )
        }
        
        // Dinner: 5pm - 8pm
        if hour >= 17 && hour < 20 {
            return .dining(
                hall: "J2 Dining",
                status: "Open · Busy 🟡"
            )
        }
        
        return nil
    }
    
    private func checkGradeScenario(_ userId: String) async -> HeroCardType? {
        do {
            // GradeCal 데이터 확인
            let coursesDoc = try await db
                .collection("users")
                .document(userId)
                .collection("gradecal_courses")
                .getDocuments()
            
            for doc in coursesDoc.documents {
                guard let data = doc.data() as? [String: Any],
                      let courseName = data["name"] as? String,
                      let gradeItems = data["gradeItems"] as? [[String: Any]] else {
                    continue
                }
                
                // 채점 안 된 항목이 있는지 확인
                let hasUngraded = gradeItems.contains { item in
                    item["scoreReceived"] == nil
                }
                
                if hasUngraded {
                    return .gradeScenario(
                        course: courseName,
                        requirement: "Final ≥ 85% for A"
                    )
                }
            }
            
            return nil
            
        } catch {
            print("❌ Error checking grades: \(error)")
            return nil
        }
    }
    
    private func checkStudyProgress(_ userId: String) async -> HeroCardType? {
        do {
            // 오늘 공부 시간 확인
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            
            let sessionsDoc = try await db
                .collection("users")
                .document(userId)
                .collection("study_sessions")
                .whereField("startTime", isGreaterThanOrEqualTo: startOfDay)
                .getDocuments()
            
            let todayMinutes = sessionsDoc.documents.reduce(0) { total, doc in
                guard let duration = doc.data()["duration"] as? TimeInterval else {
                    return total
                }
                return total + Int(duration / 60)
            }
            
            // 주간 목표와 비교
            let weeklyGoal = 1000 // 예: 주 1000분
            
            if todayMinutes < 30 {
                return .studyNow(
                    todayMinutes: todayMinutes,
                    weeklyGoal: weeklyGoal
                )
            }
            
            return nil
            
        } catch {
            print("❌ Error checking study: \(error)")
            return nil
        }
    }
    
    private func hasFriends(_ userId: String) async -> Bool {
        do {
            let snapshot = try await db
                .collection("users")
                .document(userId)
                .collection("friends")
                .limit(to: 1)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
            
        } catch {
            return false
        }
    }
    
    private func hasSharedSchedule(_ userId: String) async -> Bool {
        do {
            // 보낸 요청 중 수락된 게 있는지
            let sentRequests = try await db
                .collection("timetableShareRequests")
                .whereField("fromUserId", isEqualTo: userId)
                .whereField("status", isEqualTo: "accepted")
                .limit(to: 1)
                .getDocuments()
            
            if !sentRequests.documents.isEmpty {
                return true
            }
            
            // 받은 요청 중 수락한 게 있는지
            let receivedRequests = try await db
                .collection("timetableShareRequests")
                .whereField("toUserId", isEqualTo: userId)
                .whereField("status", isEqualTo: "accepted")
                .limit(to: 1)
                .getDocuments()
            
            return !receivedRequests.documents.isEmpty
            
        } catch {
            return false
        }
    }
}
