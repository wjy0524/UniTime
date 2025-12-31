import SwiftUI

struct AIChatView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var chatStore: ChatStore
    @StateObject private var viewModel: AIChatViewModel

    @State private var messageText = ""
    let onMenuTap: () -> Void

    init(chatStore: ChatStore, onMenuTap: @escaping () -> Void) {
        self.chatStore = chatStore
        self.onMenuTap = onMenuTap
        _viewModel = StateObject(
            wrappedValue: AIChatViewModel(chatStore: chatStore)
        )
    }

    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        if viewModel.messages.isEmpty {
                            AIChatEmptyView()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }

                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                        Text("Thinking...")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                HStack {
                    TextField("Ask anything...", text: $messageText)
                        .padding(14)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty || viewModel.isLoading)
                }
                .padding()
                .background(Color.white)
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // ☰ GPT-style menu
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    func sendMessage() {
        let text = messageText
        messageText = ""
        Task {
            await viewModel.sendMessage(text)
        }
    }
}
