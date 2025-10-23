
//
//  FoodDetailView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 10/23/25.
//

import SwiftUI

struct FoodDetailView: View {
    let food: FoodItem   // ✅ 이제 LegacyFoodItem 말고 FoodItem 사용
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                
                // 🔹 음식 이름
                Text(food.name)
                    .font(.largeTitle.bold())
                    .padding(.bottom, 8)
                
                // 🔹 영양 정보
                if let n = food.nutrition {
                    Group {
                        Text("Calories: \(n.calories ?? 0)")
                        Text("Protein: \(n.protein ?? 0, specifier: "%.1f") g")
                        Text("Fat: \(n.fat ?? 0, specifier: "%.1f") g")
                        Text("Carbs: \(n.carbs ?? 0, specifier: "%.1f") g")
                    }
                    .font(.subheadline)
                }
                
                Divider()
                
                // 🔹 알러지 정보
                if let allergens = food.allergens, !allergens.isEmpty {
                    Text("⚠️ Contains: \(allergens.joined(separator: ", "))")
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                // 🔹 태그 표시 (예: Vegan, Halal 등)
                if let tags = food.tags, !tags.isEmpty {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
                
                // 🔹 재료 정보
                if let ing = food.ingredients {
                    Text("🧂 Ingredients:\n\(ing)")
                        .font(.footnote)
                        .padding(.top, 5)
                }
            }
            .padding()
        }
        .navigationTitle("Food Detail")
    }
}
