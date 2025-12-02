//
//  MyListingsView.swift
//  Quad-2025-project
//
//  Created for Marketplace Feature
//

import SwiftUI

struct MyListingsView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: MarketplaceItem?
    @State private var itemToEdit: MarketplaceItem?
    @State private var itemToDelete: MarketplaceItem?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.myListings.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.myListings) { item in
                                MyListingCard(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            itemToDelete = item
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            itemToEdit = item
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(Color("UTAustinOrange"))
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Listings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.fetchMyListings()
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item, viewModel: viewModel)
            }
            .sheet(item: $itemToEdit) { item in
                EditListingView(viewModel: viewModel, item: item)
            }
            .alert("Delete Listing", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete, let itemId = item.id {
                        viewModel.deleteItem(itemId) { success in
                            if success {
                                viewModel.fetchMyListings()
                            }
                        }
                    }
                }
            } message: {
                if let item = itemToDelete {
                    Text(
                        "Are you sure you want to delete \"\(item.title)\"? This cannot be undone.")
                }
            }
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Listings Yet")
                .font(.title2)
                .bold()

            Text("Create your first listing to start selling!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - My Listing Card

struct MyListingCard: View {
    let item: MarketplaceItem

    var body: some View {
        HStack(spacing: 12) {
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
                        .overlay(ProgressView())
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(8)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text("$\(String(format: "%.2f", item.price))")
                    .font(.headline)
                    .foregroundColor(Color("UTAustinOrange"))

                HStack {
                    Text(item.condition.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status Badge
            VStack {
                if item.isAvailable {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(6)
                } else {
                    Text("Sold")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .cornerRadius(6)
                }

                Spacer()
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Preview

struct MyListingsView_Previews: PreviewProvider {
    static var previews: some View {
        MyListingsView(viewModel: MarketplaceViewModel())
    }
}
