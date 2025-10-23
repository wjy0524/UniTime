//
//  DiningViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/15/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class DiningViewModel: ObservableObject {
    @Published var categories: [String: [FoodItem]] = [:]
    @Published var errorMessage: String? = nil
    private let db = Firestore.firestore()
    
    func fetchMenu(hall: String) {
        Task {
            do {
                let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
                let docId = "\(hall)_\(today)"
                let docRef = db.collection("meals").document(String(docId))
                let snapshot = try await docRef.getDocument()
                
                guard let data = try? snapshot.data(as: DiningCategories.self),
                      let categoryMap = data.categories else {
                    errorMessage = "⚠️ No categories found for \(hall)."
                    return
                }

                var newCategories: [String: [FoodItem]] = [:]
                let mealOrder = ["breakfast", "lunch", "dinner"]
                
                // ✅ 끼니 순으로 정렬
                let sortedKeys = categoryMap.keys.sorted { (a, b) in
                    let mealA = mealOrder.firstIndex(where: { a.lowercased().hasPrefix($0) }) ?? 999
                    let mealB = mealOrder.firstIndex(where: { b.lowercased().hasPrefix($0) }) ?? 999
                    return mealA < mealB
                }

                // ✅ 병렬 fetch (TaskGroup)
                for categoryKey in sortedKeys {
                    guard let ids = categoryMap[categoryKey] else { continue }
                    
                    var results: [FoodItem] = []
                    var seen = Set<String>() // 중복방지

                    try await withThrowingTaskGroup(of: FoodItem?.self) { group in
                        for id in ids {
                            group.addTask {
                                let ref = docRef.collection("food_items").document(id)
                                let snap = try await ref.getDocument()
                                return try? snap.data(as: FoodItem.self)
                            }
                        }
                        
                        for try await item in group {
                            if let food = item, !seen.contains(food.name) {
                                seen.insert(food.name)
                                results.append(food)
                            }
                        }
                    }

                    newCategories[categoryKey] = results
                }

                // ✅ UI 업데이트
                self.categories = newCategories
                self.errorMessage = nil
                
            } catch {
                errorMessage = "⚠️ \(error.localizedDescription)"
                print("❌ DiningViewModel fetchMenu error: \(error)")
            }
        }
    }
}



