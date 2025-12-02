//
//  CreateListingView.swift
//  Quad-2025-project
//
//  Created for Marketplace Feature
//

import PhotosUI
import SwiftUI

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MarketplaceViewModel

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priceText: String = ""
    @State private var location: String = ""
    @State private var selectedCategory: MarketplaceItem.ItemCategory = .other
    @State private var selectedCondition: MarketplaceItem.ItemCondition = .good
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Photos Section
                    photosSection

                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        TextField("What are you selling?", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Price Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price")
                            .font(.headline)
                        HStack {
                            Text("$")
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $priceText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(MarketplaceItem.ItemCategory.allCases, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                }
                                .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }

                    // Condition Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Condition")
                            .font(.headline)
                        Picker("Condition", selection: $selectedCondition) {
                            ForEach(MarketplaceItem.ItemCondition.allCases, id: \.self) {
                                condition in
                                Text(condition.rawValue).tag(condition)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Description Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        TextEditor(text: $description)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Location Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                        TextField("e.g., West Campus, Jester", text: $location)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }
            .navigationTitle("Create Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createListing()
                    }
                    .disabled(!isValidForm)
                    .bold()
                }
            }
        }
    }

    // MARK: - Photos Section

    var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos (Optional)")
                .font(.headline)

            if selectedImages.isEmpty {
                // Empty state
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Add up to 5 photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    )
                }
                .onChange(of: selectedPhotos) {
                    loadImages(from: selectedPhotos)
                }
            } else {
                // Selected images grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)

                                // Remove button
                                Button {
                                    selectedImages.remove(at: index)
                                    selectedPhotos.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(4)
                            }
                        }

                        // Add more button
                        if selectedImages.count < 5 {
                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 5 - selectedImages.count,
                                matching: .images
                            ) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 100, height: 100)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .onChange(of: selectedPhotos) {
                                loadImages(from: selectedPhotos)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Validation

    var isValidForm: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !priceText.isEmpty
            && Double(priceText) != nil
            && !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    func loadImages(from items: [PhotosPickerItem]) {
        print("🔔 CREATE LISTING: Loading \(items.count) photo items")
        // Don't remove existing images, just load new ones
        Task {
            for (index, item) in items.enumerated() {
                print("  📸 Loading image \(index + 1)/\(items.count)...")
                if let data = try? await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                {
                    await MainActor.run {
                        if !selectedImages.contains(where: { $0.pngData() == image.pngData() }) {
                            selectedImages.append(image)
                            print(
                                "  ✅ Image \(index + 1) added. Total images: \(selectedImages.count)"
                            )
                        } else {
                            print("  ⚠️ Image \(index + 1) already exists, skipping")
                        }
                    }
                } else {
                    print("  ❌ Failed to load image \(index + 1)")
                }
            }
        }
    }

    func createListing() {
        guard let price = Double(priceText) else { return }

        print("🔔 CREATE LISTING: Creating listing with \(selectedImages.count) images")
        print("  📊 Title: \(title)")
        print("  💰 Price: $\(price)")
        print("  📦 Category: \(selectedCategory.rawValue)")

        if selectedImages.isEmpty {
            print("  ⚠️ WARNING: No images selected!")
        } else {
            selectedImages.enumerated().forEach { index, image in
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    print("  ✅ Image \(index + 1): Size = \(imageData.count) bytes")
                } else {
                    print("  ❌ Image \(index + 1): Failed to convert to JPEG")
                }
            }
        }

        viewModel.createItem(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            price: price,
            category: selectedCategory,
            condition: selectedCondition,
            location: location.trimmingCharacters(in: .whitespaces),
            images: selectedImages
        ) { success in
            if success {
                print("✅ CREATE LISTING: Listing created successfully")
                dismiss()
            } else {
                print("❌ CREATE LISTING: Failed to create listing")
            }
        }
    }
}

// MARK: - Preview

struct CreateListingView_Previews: PreviewProvider {
    static var previews: some View {
        CreateListingView(viewModel: MarketplaceViewModel())
    }
}
