//
//  MealMenu.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 9/15/25.
//
import Foundation

struct MealCategory: Codable {
    var category: String
    var items: [String]
}

struct MealMenu: Codable {
    var breakfast: [MealCategory]?
    var lunch: [MealCategory]?
    var dinner: [MealCategory]?
}
