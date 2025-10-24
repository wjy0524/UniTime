//
//  DiningMenuView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/15/25.
//

import SwiftUI
import Shimmer

struct DiningMenuView: View {
    let hall: String
    @StateObject private var viewModel = DiningViewModel()
    
    // 🍳 끼니별 탭 & 색상
    @State private var selectedMeal = "lunch"
    private let mealTabs = ["breakfast", "lunch", "dinner"]
    private let mealColors: [String: Color] = [
        "breakfast": .orange,
        "lunch": .blue,
        "dinner": .purple
    ]
    private let mealIcons: [String: String] = [
        "breakfast": "🍳",
        "lunch": "🥗",
        "dinner": "🍝"
    ]
    
    // 🔹 펼침 상태
    @State private var expandedCategories: [String: Bool] = [:]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if !viewModel.categories.isEmpty {
                VStack(spacing: 10) {
                    // 🕑 Meal 탭 바
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(mealTabs, id: \.self) { meal in
                                Text("\(mealIcons[meal] ?? "🍽️") \(meal.capitalized)")
                                    .font(.headline)
                                    .foregroundColor(selectedMeal == meal ? .white : .gray)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                    .background(selectedMeal == meal ? mealColors[meal] ?? .gray : Color(.systemGray5))
                                    .cornerRadius(20)
                                    .onTapGesture {
                                        withAnimation { selectedMeal = meal }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    
                    // 🍽 실제 메뉴 섹션
                    ScrollView {
                        VStack(spacing: 22) {
                            ForEach(groupedByMeal().filter { $0.key == selectedMeal }, id: \.key) { meal, categories in
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(categories.sorted(by: { $0.key < $1.key }), id: \.key) { category, items in
                                        
                                        // 섹션 토글 버튼
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                expandedCategories[category]?.toggle()
                                            }
                                        } label: {
                                            HStack {
                                                Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: (expandedCategories[category] ?? true) ? "chevron.up" : "chevron.down")
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.vertical, 6)
                                        }
                                        
                                        // 메뉴 아이템 리스트
                                        if expandedCategories[category] ?? true {
                                            VStack(alignment: .leading, spacing: 10) {
                                                ForEach(items, id: \.name) { food in
                                                    NavigationLink(destination: FoodDetailView(food: food)) {
                                                        mealRow(for: food)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.horizontal, 4)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        }
                                        
                                        Divider().padding(.top, 4)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            } else if let error = viewModel.errorMessage {
                Text("⚠️ \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                // 🔸 Shimmer 로딩 UI
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(alignment: .leading, spacing: 10) {
                                // 제목 부분
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 160, height: 20)
                                    .shimmering()
                                
                                // 내용 카드 모양
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 100)
                                    .shimmering()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }

        }
        .navigationTitle(hall)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // ✅ 오늘 날짜를 Firestore 문서명 형식에 맞게 생성
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(identifier: "America/Chicago") // ✅ Austin 시간대
                let today = formatter.string(from: Date())

                // ✅ 실제 Firestore 문서 키 (예: "J2_JCL_2025-10-23")
                let fullKey = "\(hall)_\(today)"
                print("📦 Fetching Firestore doc:", fullKey) // debug print

                // ✅ 완전한 키로 fetch 호출
                viewModel.fetchMenu(hall: fullKey)
        }
    }
}

// MARK: - Helper Functions
extension DiningMenuView {
    
    /// 🍽 끼니별 카테고리 그룹화
    private func groupedByMeal() -> [(key: String, value: [String: [FoodItem]])] {
        let mealOrder = ["breakfast", "lunch", "dinner"]
        
        // 1️⃣ 끼니 이름별 그룹화
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

        // 3️⃣ 끼니 순서 정렬
        return converted.sorted { lhs, rhs in
            let leftIndex = mealOrder.firstIndex(of: lhs.key) ?? 99
            let rightIndex = mealOrder.firstIndex(of: rhs.key) ?? 99
            return leftIndex < rightIndex
        }
    }
    
    /// 🍱 개별 음식 카드
    @ViewBuilder
    private func mealRow(for food: FoodItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(food.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if let cals = food.nutrition?.calories {
                    Text("\(Int(cals)) kcal")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if let tags = food.tags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
            
            if let allergens = food.allergens, !allergens.isEmpty {
                Text("⚠️ \(allergens.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

