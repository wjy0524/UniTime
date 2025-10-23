//
//  MealMenu.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/15/25.
//

import Foundation
import FirebaseFirestore

// 🔹 영양 정보
// 🔹 영양 정보
struct NutritionInfo: Codable {
    var calories: Double?
    var protein: Double?
    var fat: Double?
    var carbs: Double?

    enum CodingKeys: String, CodingKey {
        case calories, protein, fat, carbs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func decodeDouble(forKey key: CodingKeys) -> Double? {
            // 🔸 1) 숫자(Double)로 시도
            if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return doubleValue
            }
            // 🔸 2) 문자열(String) → Double로 변환 시도
            if let stringValue = try? container.decode(String.self, forKey: key),
               let doubleValue = Double(stringValue) {
                return doubleValue
            }
            // 🔸 3) Int로 저장된 경우도 처리
            if let intValue = try? container.decode(Int.self, forKey: key) {
                return Double(intValue)
            }
            return nil
        }

        calories = decodeDouble(forKey: .calories)
        protein = decodeDouble(forKey: .protein)
        fat = decodeDouble(forKey: .fat)
        carbs = decodeDouble(forKey: .carbs)
    }

    // 🔹 기본 initializer
    init(calories: Double? = nil, protein: Double? = nil, fat: Double? = nil, carbs: Double? = nil) {
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
    }
}


// 🔹 개별 음식 데이터
struct FoodItem: Identifiable, Codable {
    var id: String?          // @DocumentID 필요 없음
    var name: String
    var nutrition: NutritionInfo?
    var allergens: [String]?
    var tags: [String]?
    var ingredients: String?
}

// 🔹 상위 카테고리 문서 구조
struct DiningCategories: Codable {
    var categories: [String: [String]]?
    var updated_at: String?
}



