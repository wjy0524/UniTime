//
//  ItemDetailView.swift
//  Quad-2025-project
//
//  Created for Marketplace Feature
//

import SwiftUI

struct ItemDetailView: View {
    let item: MarketplaceItem
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex = 0
    @State private var showingContactSeller = false
    @State private var showingEditListing = false
    @State private var showingChat = false
    @State private var chatConversation: ChatConversation?
    @StateObject private var chatViewModel = ChatViewModel()

    var isMyListing: Bool {
        item.sellerId == viewModel.currentUserId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Carousel
                    imageCarousel

                    VStack(alignment: .leading, spacing: 16) {
                        // Price & Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("$\(String(format: "%.2f", item.price))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color("UTAustinOrange"))

                            Text(item.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        Divider()

                        // Condition & Category
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Condition")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(item.condition.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            Divider()
                                .frame(height: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Category")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: item.category.icon)
                                        .font(.caption)
                                    Text(item.category.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }

                        if !item.location.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                    Text(item.location)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }

                        Divider()

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(item.description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }

                        Divider()

                        // Seller Info
                        sellerInfo

                        // Posted Date
                        Text("Posted \(timeAgo(item.timestamp))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isMyListing {
                        Button {
                            showingEditListing = true
                        } label: {
                            Text("Edit")
                                .foregroundColor(Color("UTAustinOrange"))
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditListing) {
                EditListingView(viewModel: viewModel, item: item)
            }
            .sheet(isPresented: $showingChat) {
                if let conversation = chatConversation {
                    ChatView(conversation: conversation, chatViewModel: chatViewModel)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !isMyListing && item.isAvailable {
                    contactSellerButton
                } else if isMyListing {
                    myListingButtons
                }
            }
        }
    }

    // MARK: - Image Carousel

    var imageCarousel: some View {
        VStack {
            if item.imageURLs.isEmpty {
                // No images placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No photos")
                                .foregroundColor(.secondary)
                        }
                    )
            } else {
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(item.imageURLs.enumerated()), id: \.offset) { index, imageURL in
                        if let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(ProgressView())
                            }
                            .frame(height: 300)
                            .tag(index)
                        }
                    }
                }
                .frame(height: 300)
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Image counter
                if item.imageURLs.count > 1 {
                    Text("\(currentImageIndex + 1) / \(item.imageURLs.count)")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, -40)
                }
            }
        }
    }

    // MARK: - Seller Info

    var sellerInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seller")
                .font(.headline)

            HStack(spacing: 12) {
                // Profile Image
                if let imageURL = item.sellerProfileImage,
                    let url = URL(string: imageURL)
                {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(item.sellerUsername.prefix(1).uppercased()))
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.sellerUsername)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("View Profile")
                        .font(.caption)
                        .foregroundColor(Color("UTAustinOrange"))
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Contact Seller Button

    var contactSellerButton: some View {
        Button {
            startConversation()
        } label: {
            HStack {
                Image(systemName: "message.fill")
                Text("Contact Seller")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("UTAustinOrange"))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - My Listing Buttons

    var myListingButtons: some View {
        HStack(spacing: 12) {
            if item.isAvailable {
                Button {
                    markAsSold()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Sold")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            } else {
                Text("Sold")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            }

            Button(role: .destructive) {
                deleteItem()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Helper Functions

    func timeAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "just now"
        }
    }

    func markAsSold() {
        guard let itemId = item.id else { return }
        viewModel.markAsSold(itemId)
        dismiss()
    }

    func deleteItem() {
        guard let itemId = item.id else { return }
        viewModel.deleteItem(itemId) { success in
            if success {
                dismiss()
            }
        }
    }

    // MARK: - Start Conversation

    func startConversation() {
        Task {
            do {
                // Get seller info
                let sellerDoc = try await viewModel.db.collection("users").document(item.sellerId)
                    .getDocument()
                guard let sellerData = sellerDoc.data(),
                    let sellerUsername = sellerData["username"] as? String
                else {
                    return
                }

                let sellerImage = sellerData["profileImageURL"] as? String

                let conversationId = try await chatViewModel.getOrCreateConversation(
                    withUserId: item.sellerId,
                    otherUsername: sellerUsername,
                    otherUserImage: sellerImage,
                    forItem: item
                )

                // Load the conversation
                let conversationDoc = try await viewModel.db.collection("chatConversations")
                    .document(conversationId).getDocument()
                if let conversation = try? conversationDoc.data(as: ChatConversation.self) {
                    await MainActor.run {
                        chatConversation = conversation
                        showingChat = true
                    }
                }
            } catch {
                print("❌ Error starting conversation: \(error)")
            }
        }
    }
}

// MARK: - Preview

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(
            item: MarketplaceItem(
                sellerId: "123",
                sellerUsername: "testuser",
                title: "Test Item",
                description: "This is a test description",
                price: 29.99,
                category: .textbooks,
                condition: .good,
                location: "West Campus"
            ),
            viewModel: MarketplaceViewModel()
        )
    }
}
