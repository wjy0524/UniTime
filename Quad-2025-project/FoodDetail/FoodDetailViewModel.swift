//
//  FoodDetailViewModel.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 10/22/25.
//


import Foundation
import FirebaseFirestore

@MainActor
class FoodDetailViewModel: ObservableObject {
    @Published var foodItem: FoodItem?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchFoodItem(by id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let doc = try await db.collection("food_items").document(id).getDocument()
            if let data = try? doc.data(as: FoodItem.self) {
                // ✅ FirestoreDecoder 자동으로 Codable 매핑
                self.foodItem = data
            } else {
                self.errorMessage = "⚠️ Item not found."
            }
        } catch {
            self.errorMessage = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

