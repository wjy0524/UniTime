//
//  EditListingView.swift
//  Quad-2025-project
//
//  Created for Marketplace Feature
//

import PhotosUI
import SwiftUI

struct EditListingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MarketplaceViewModel
    let item: MarketplaceItem

    @State private var title: String
    @State private var description: String
    @State private var priceText: String
    @State private var location: String
    @State private var selectedCategory: MarketplaceItem.ItemCategory
    @State private var selectedCondition: MarketplaceItem.ItemCondition
    @State private var isAvailable: Bool

    init(viewModel: MarketplaceViewModel, item: MarketplaceItem) {
        self.viewModel = viewModel
        self.item = item
        _title = State(initialValue: item.title)
        _description = State(initialValue: item.description)
        _priceText = State(initialValue: String(format: "%.2f", item.price))
        _location = State(initialValue: item.location)
        _selectedCategory = State(initialValue: item.category)
        _selectedCondition = State(initialValue: item.condition)
        _isAvailable = State(initialValue: item.isAvailable)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Existing Photos Display (read-only for now)
                    if !item.imageURLs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photos")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(item.imageURLs, id: \.self) { imageURL in
                                        if let url = URL(string: imageURL) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .overlay(ProgressView())
                                            }
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }

                            Text("Note: Photo editing not available yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

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

                    // Availability Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Availability")
                            .font(.headline)
                        Toggle(isOn: $isAvailable) {
                            HStack {
                                Image(
                                    systemName: isAvailable
                                        ? "checkmark.circle.fill" : "xmark.circle.fill"
                                )
                                .foregroundColor(isAvailable ? .green : .gray)
                                Text(isAvailable ? "Available" : "Sold")
                            }
                        }
                        .tint(Color("UTAustinOrange"))
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateListing()
                    }
                    .disabled(!isValidForm)
                    .bold()
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

    func updateListing() {
        guard let itemId = item.id,
            let price = Double(priceText)
        else { return }

        viewModel.updateItem(
            itemId: itemId,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            price: price,
            category: selectedCategory,
            condition: selectedCondition,
            location: location.trimmingCharacters(in: .whitespaces),
            isAvailable: isAvailable
        ) { success in
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

struct EditListingView_Previews: PreviewProvider {
    static var previews: some View {
        EditListingView(
            viewModel: MarketplaceViewModel(),
            item: MarketplaceItem(
                sellerId: "123",
                sellerUsername: "testuser",
                title: "Test Item",
                description: "This is a test description",
                price: 29.99,
                category: .textbooks,
                condition: .good,
                location: "West Campus"
            )
        )
    }
}
