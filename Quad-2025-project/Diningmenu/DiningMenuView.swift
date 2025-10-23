import SwiftUI

struct DiningMenuView: View {
    let hall: String
    @StateObject private var viewModel = DiningViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if !viewModel.categories.isEmpty {
                ScrollView {
                    VStack(spacing: 20) {
                        // 끼니별 정렬된 섹션
                        ForEach(groupedByMeal(), id: \.key) { meal, categories in
                            VStack(alignment: .leading, spacing: 14) {
                                
                                // 🍳 끼니 제목
                                Text(meal.uppercased())
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(colorForMeal(meal))
                                    .cornerRadius(10)
                                    .padding(.leading, 6)
                                
                                // 🍽 끼니 내 카테고리 카드 묶음
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(categories.sorted(by: { $0.key < $1.key }), id: \.key) { category, items in
                                        VStack(alignment: .leading, spacing: 10) {
                                            // 카테고리 제목
                                            Text(category.replacingOccurrences(of: "_", with: " ").uppercased())
                                                .font(.headline)
                                                .foregroundColor(.primary.opacity(0.7))
                                            
                                            // 각 음식 아이템
                                            ForEach(items, id: \.name) { food in
                                                NavigationLink(destination: FoodDetailView(food: food)) {
                                                    mealRow(for: food)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.85))
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 0)
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            } else if let error = viewModel.errorMessage {
                Text("⚠️ \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ProgressView("Loading menu…")
                    .padding()
            }
        }
        .navigationTitle(hall)
        .onAppear {
            viewModel.fetchMenu(hall: hall)
        }
    }
}

// MARK: - Helper Functions
extension DiningMenuView {
    
    /// 🍽 끼니별 카테고리 그룹화
    private func groupedByMeal() -> [(key: String, value: [String: [FoodItem]])] {
        let mealOrder = ["breakfast", "lunch", "dinner"]
        
        // 1️⃣ 끼니 이름별 그룹화 (예: "breakfast" → ["breakfast_bakery", "breakfast_fruit"])
        let grouped = Dictionary(grouping: viewModel.categories.keys) { key in
            key.split(separator: "_").first.map(String.init) ?? "other"
        }

        // 2️⃣ 각 그룹 안의 key를 실제 FoodItem 딕셔너리로 변환
        let converted: [(key: String, value: [String: [FoodItem]])] = grouped.map { (meal, categoryKeys) in
            let categoryDict = Dictionary(uniqueKeysWithValues: categoryKeys.compactMap { catKey in
                if let items = viewModel.categories[catKey] {
                    return (catKey, items)
                } else {
                    return nil
                }
            })
            return (key: meal, value: categoryDict)
        }

        // 3️⃣ 끼니 순서에 따라 정렬
        return converted.sorted { lhs, rhs in
            let leftIndex = mealOrder.firstIndex(of: lhs.key) ?? 99
            let rightIndex = mealOrder.firstIndex(of: rhs.key) ?? 99
            return leftIndex < rightIndex
        }
    }



    
    /// 🔹 끼니별 색상
    private func colorForMeal(_ meal: String) -> Color {
        switch meal.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .blue
        case "dinner": return .purple
        default: return .gray
        }
    }
    
    /// 🍱 개별 음식 셀
    @ViewBuilder
    private func mealRow(for food: FoodItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(food.name)
                .font(.body.bold())
                .foregroundColor(.blue)
            
            if let calories = food.nutrition?.calories {
                Text("\(calories) kcal")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let tags = food.tags, !tags.isEmpty {
                HStack(spacing: 6) {
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
            
            if let allergens = food.allergens, !allergens.isEmpty {
                Text("⚠️ Contains: \(allergens.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

