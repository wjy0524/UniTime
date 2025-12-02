//
//  MarketplaceItem.swift
//  Quad-2025-project
//
//  Created for Marketplace Feature
//

import FirebaseFirestore
import Foundation

struct MarketplaceItem: Identifiable, Codable {
    @DocumentID var id: String?
    let sellerId: String
    let sellerUsername: String
    let sellerProfileImage: String?
    var title: String
    var description: String
    var price: Double
    var category: ItemCategory
    var condition: ItemCondition
    var imageURLs: [String]
    let timestamp: Date
    var isAvailable: Bool
    var location: String

    enum ItemCategory: String, Codable, CaseIterable {
        case textbooks = "Textbooks"
        case electronics = "Electronics"
        case furniture = "Furniture"
        case clothing = "Clothing"
        case supplies = "School Supplies"
        case tickets = "Event Tickets"
        case other = "Other"

        var icon: String {
            switch self {
            case .textbooks: return "book.fill"
            case .electronics: return "laptopcomputer"
            case .furniture: return "chair.fill"
            case .clothing: return "tshirt.fill"
            case .supplies: return "pencil"
            case .tickets: return "ticket.fill"
            case .other: return "tag.fill"
            }
        }
    }

    enum ItemCondition: String, Codable, CaseIterable {
        case new = "New"
        case likeNew = "Like New"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sellerId
        case sellerUsername
        case sellerProfileImage
        case title
        case description
        case price
        case category
        case condition
        case imageURLs
        case timestamp
        case isAvailable
        case location
    }

    init(
        id: String? = nil,
        sellerId: String,
        sellerUsername: String,
        sellerProfileImage: String? = nil,
        title: String,
        description: String,
        price: Double,
        category: ItemCategory,
        condition: ItemCondition,
        imageURLs: [String] = [],
        timestamp: Date = Date(),
        isAvailable: Bool = true,
        location: String = ""
    ) {
        self.id = id
        self.sellerId = sellerId
        self.sellerUsername = sellerUsername
        self.sellerProfileImage = sellerProfileImage
        self.title = title
        self.description = description
        self.price = price
        self.category = category
        self.condition = condition
        self.imageURLs = imageURLs
        self.timestamp = timestamp
        self.isAvailable = isAvailable
        self.location = location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        sellerId = try container.decode(String.self, forKey: .sellerId)
        sellerUsername = try container.decode(String.self, forKey: .sellerUsername)
        sellerProfileImage = try container.decodeIfPresent(String.self, forKey: .sellerProfileImage)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        price = try container.decode(Double.self, forKey: .price)
        category = try container.decode(ItemCategory.self, forKey: .category)
        condition = try container.decode(ItemCondition.self, forKey: .condition)
        imageURLs = try container.decode([String].self, forKey: .imageURLs)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        location = try container.decode(String.self, forKey: .location)

        // Handle Firestore Timestamp
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(sellerId, forKey: .sellerId)
        try container.encode(sellerUsername, forKey: .sellerUsername)
        try container.encodeIfPresent(sellerProfileImage, forKey: .sellerProfileImage)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(price, forKey: .price)
        try container.encode(category, forKey: .category)
        try container.encode(condition, forKey: .condition)
        try container.encode(imageURLs, forKey: .imageURLs)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(isAvailable, forKey: .isAvailable)
        try container.encode(location, forKey: .location)
    }
}
