//
//  MarketplaceViewModel.swift
//  Quad-2025-project
//
//  Created for Marketplace Feature
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI

@MainActor
class MarketplaceViewModel: ObservableObject {
    @Published var items: [MarketplaceItem] = []
    @Published var myListings: [MarketplaceItem] = []
    @Published var filteredItems: [MarketplaceItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    @Published var searchText: String = ""
    @Published var selectedCategory: MarketplaceItem.ItemCategory?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    init() {
        startListening()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Fetch Items

    func startListening() {
        print("✅ MARKETPLACE: Starting to listen for items")

        listener = db.collection("marketplaceItems")
            .whereField("isAvailable", isEqualTo: true)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ MARKETPLACE ERROR: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load items: \(error.localizedDescription)"
                    self.showingError = true
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ MARKETPLACE: No documents found")
                    return
                }

                self.items = documents.compactMap { doc in
                    do {
                        let item = try doc.data(as: MarketplaceItem.self)
                        return item
                    } catch {
                        print("❌ MARKETPLACE: Failed to decode item \(doc.documentID): \(error)")
                        return nil
                    }
                }

                print("✅ MARKETPLACE: Loaded \(self.items.count) items")
                self.filterItems()
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Fetch My Listings

    func fetchMyListings() {
        guard !currentUserId.isEmpty else { return }

        print("🔔 MARKETPLACE: Fetching listings for user: \(currentUserId)")

        db.collection("marketplaceItems")
            .whereField("sellerId", isEqualTo: currentUserId)
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print(
                        "❌ MARKETPLACE: Failed to fetch my listings: \(error.localizedDescription)")
                    return
                }

                let listings =
                    snapshot?.documents.compactMap { doc in
                        try? doc.data(as: MarketplaceItem.self)
                    } ?? []

                DispatchQueue.main.async {
                    self.myListings = listings
                    print("✅ MARKETPLACE: Loaded \(self.myListings.count) of my listings")
                }
            }
    }

    // MARK: - Filter Items

    func filterItems() {
        var filtered = items

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText)
                    || item.description.localizedCaseInsensitiveContains(searchText)
                    || item.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        filteredItems = filtered
        print("✅ MARKETPLACE: Filtered to \(filteredItems.count) items")
    }

    // MARK: - Create Item

    func createItem(
        title: String,
        description: String,
        price: Double,
        category: MarketplaceItem.ItemCategory,
        condition: MarketplaceItem.ItemCondition,
        location: String,
        images: [UIImage],
        completion: @escaping (Bool) -> Void
    ) {
        guard !currentUserId.isEmpty else {
            errorMessage = "You must be logged in to create a listing"
            showingError = true
            completion(false)
            return
        }

        isLoading = true

        print("🔔 MARKETPLACE: Creating item with \(images.count) images")

        // Fetch user info
        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Failed to fetch user info: \(error.localizedDescription)"
                self.showingError = true
                self.isLoading = false
                completion(false)
                return
            }

            guard let data = snapshot?.data(),
                let username = data["username"] as? String
            else {
                self.errorMessage = "Failed to get username"
                self.showingError = true
                self.isLoading = false
                completion(false)
                return
            }

            let profileImageURL = data["profileImageURL"] as? String

            // Upload images first
            print("🔔 MARKETPLACE: Starting image upload...")
            self.uploadImages(images) { imageURLs in
                print("✅ MARKETPLACE: Upload complete. Got \(imageURLs.count) URLs")
                imageURLs.forEach { url in
                    print("  📸 Image URL: \(url)")
                }
                let item = MarketplaceItem(
                    sellerId: self.currentUserId,
                    sellerUsername: username,
                    sellerProfileImage: profileImageURL,
                    title: title,
                    description: description,
                    price: price,
                    category: category,
                    condition: condition,
                    imageURLs: imageURLs,
                    location: location
                )

                do {
                    let docRef = try self.db.collection("marketplaceItems").addDocument(from: item)
                    print("✅ MARKETPLACE: Item created successfully with ID: \(docRef.documentID)")
                    print("  📊 Item has \(item.imageURLs.count) image URLs")
                    self.isLoading = false
                    completion(true)
                } catch {
                    print("❌ MARKETPLACE: Failed to create item: \(error.localizedDescription)")
                    self.errorMessage = "Failed to create listing: \(error.localizedDescription)"
                    self.showingError = true
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }

    // MARK: - Update Item

    func updateItem(
        itemId: String,
        title: String,
        description: String,
        price: Double,
        category: MarketplaceItem.ItemCategory,
        condition: MarketplaceItem.ItemCondition,
        location: String,
        isAvailable: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("marketplaceItems").document(itemId).updateData([
            "title": title,
            "description": description,
            "price": price,
            "category": category.rawValue,
            "condition": condition.rawValue,
            "location": location,
            "isAvailable": isAvailable,
        ]) { error in
            if let error = error {
                print("❌ MARKETPLACE: Failed to update item: \(error.localizedDescription)")
                self.errorMessage = "Failed to update listing: \(error.localizedDescription)"
                self.showingError = true
                completion(false)
            } else {
                print("✅ MARKETPLACE: Item updated successfully")
                completion(true)
            }
        }
    }

    // MARK: - Delete Item

    func deleteItem(_ itemId: String, completion: @escaping (Bool) -> Void) {
        db.collection("marketplaceItems").document(itemId).delete { error in
            if let error = error {
                print("❌ MARKETPLACE: Failed to delete item: \(error.localizedDescription)")
                self.errorMessage = "Failed to delete listing: \(error.localizedDescription)"
                self.showingError = true
                completion(false)
            } else {
                print("✅ MARKETPLACE: Item deleted successfully")
                completion(true)
            }
        }
    }

    // MARK: - Mark as Sold

    func markAsSold(_ itemId: String) {
        db.collection("marketplaceItems").document(itemId).updateData([
            "isAvailable": false
        ]) { error in
            if let error = error {
                print("❌ MARKETPLACE: Failed to mark as sold: \(error.localizedDescription)")
            } else {
                print("✅ MARKETPLACE: Item marked as sold")
            }
        }
    }

    // MARK: - Upload Images

    private func uploadImages(_ images: [UIImage], completion: @escaping ([String]) -> Void) {
        guard !images.isEmpty else {
            print("⚠️ MARKETPLACE: No images to upload")
            completion([])
            return
        }

        print("🔔 MARKETPLACE: Uploading \(images.count) images...")
        print("🔔 MARKETPLACE: Current user ID: \(currentUserId)")

        var uploadedURLs: [String] = []
        let group = DispatchGroup()

        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                print("❌ MARKETPLACE: Failed to convert image \(index) to JPEG")
                continue
            }

            print("  📸 Uploading image \(index + 1)/\(images.count)... (\(imageData.count) bytes)")

            group.enter()

            let imageName = "\(UUID().uuidString)_\(index).jpg"
            let storagePath = "marketplace_images/\(currentUserId)/\(imageName)"
            print("  📍 Storage path: \(storagePath)")

            let storageRef = storage.reference()
                .child("marketplace_images")
                .child(currentUserId)
                .child(imageName)

            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            // Try uploading with putData
            let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    let nsError = error as NSError
                    print("❌ MARKETPLACE: Image \(index) upload failed!")
                    print("   Error: \(error.localizedDescription)")
                    print("   Error domain: \(error._domain)")
                    print("   Error code: \(error._code)")

                    if error.localizedDescription.contains("permission")
                        || error.localizedDescription.contains("denied")
                    {
                        print("   ⚠️ PERMISSION DENIED - Check Firebase Storage Rules!")
                        print("   Rules needed: allow write for marketplace_images/{userId}/**")
                    } else if nsError.code == -13010 {
                        print("   ⚠️ STORAGE ERROR -13010: This usually means:")
                        print("      1. Storage rules are too restrictive")
                        print("      2. Storage bucket not properly configured")
                        print(
                            "      3. Try adding test rule: match /{allPaths=**} { allow read, write: if request.auth != null; }"
                        )
                    }
                    group.leave()
                    return
                }

                print("  ✅ Image \(index) uploaded successfully, getting download URL...")

                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("❌ MARKETPLACE: Failed to get download URL for image \(index)")
                        print("   Error: \(error.localizedDescription)")
                    } else if let urlString = url?.absoluteString {
                        print("  ✅ Got download URL for image \(index)")
                        print("     URL: \(urlString.prefix(50))...")
                        uploadedURLs.append(urlString)
                    }
                    group.leave()
                }
            }

            // Monitor upload progress
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentComplete =
                        100.0 * Double(progress.completedUnitCount)
                        / Double(progress.totalUnitCount)
                    if percentComplete.truncatingRemainder(dividingBy: 25) == 0 {
                        print("  📊 Image \(index) upload: \(Int(percentComplete))%")
                    }
                }
            }
        }

        group.notify(queue: .main) {
            print(
                "✅ MARKETPLACE: All uploads complete - \(uploadedURLs.count)/\(images.count) successful"
            )
            if uploadedURLs.isEmpty {
                print("⚠️ MARKETPLACE: No images were successfully uploaded!")
                print("   Check Firebase Storage Rules and console errors above")
            } else {
                print("📊 MARKETPLACE: Successfully uploaded URLs:")
                uploadedURLs.forEach { print("   - \(String($0.prefix(60)))...") }
            }
            completion(uploadedURLs)
        }
    }

    // MARK: - Search

    func search(query: String) {
        searchText = query
        filterItems()
    }

    func selectCategory(_ category: MarketplaceItem.ItemCategory?) {
        selectedCategory = category
        filterItems()
    }

    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        filterItems()
    }
}
