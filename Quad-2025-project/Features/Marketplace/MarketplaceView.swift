//
//  MarketplaceView.swift
//  Quad-2025-project
//
//  Created for Marketplace Feature
//

import SwiftUI

struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    @State private var showingCreateListing = false
    @State private var showingMyListings = false
    @State private var selectedItem: MarketplaceItem?

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading marketplace...")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Search Bar
                            searchBar

                            // Category Filter
                            categoryFilter

                            // Items Grid
                            if viewModel.filteredItems.isEmpty {
                                emptyStateView
                            } else {
                                itemsGrid
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Marketplace")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingMyListings = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(Color("UTAustinOrange"))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateListing = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("UTAustinOrange"))
                    }
                }
            }
            .sheet(isPresented: $showingCreateListing) {
                CreateListingView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingMyListings) {
                MyListingsView(viewModel: viewModel)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item, viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Search Bar

    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search items...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .onChange(of: viewModel.searchText) {
                    viewModel.filterItems()
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.filterItems()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Category Filter

    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Categories
                CategoryChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectCategory(nil)
                }

                // Individual Categories
                ForEach(MarketplaceItem.ItemCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
        }
    }

    // MARK: - Items Grid

    var itemsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.filteredItems) { item in
                ItemCard(item: item)
                    .onTapGesture {
                        selectedItem = item
                    }
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Items Found")
                .font(.title2)
                .bold()

            Text(
                viewModel.searchText.isEmpty
                    ? "Be the first to post an item!" : "Try a different search term"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

            if viewModel.searchText.isEmpty {
                Button {
                    showingCreateListing = true
                } label: {
                    Label("Create Listing", systemImage: "plus.circle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("UTAustinOrange"))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color("UTAustinOrange") : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Item Card

struct ItemCard: View {
    let item: MarketplaceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let firstImageURL = item.imageURLs.first,
                let url = URL(string: firstImageURL)
            {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12)
            }

            // Title
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Price
            Text("$\(String(format: "%.2f", item.price))")
                .font(.headline)
                .foregroundColor(Color("UTAustinOrange"))

            // Condition & Category
            HStack {
                Text(item.condition.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: item.category.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Preview

struct MarketplaceView_Previews: PreviewProvider {
    static var previews: some View {
        MarketplaceView()
    }
}
