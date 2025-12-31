import SwiftUI

struct ChatBubble: View {
    let message: AIChatMessage

    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }

            Text(message.text)
                .padding(14)
                .background(
                    message.isFromUser
                    ? Color.blue
                    : Color.gray.opacity(0.15)
                )
                .foregroundColor(
                    message.isFromUser
                    ? .white
                    : .primary
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 22)
                )
                .frame(
                    maxWidth: 280,
                    alignment: message.isFromUser ? .trailing : .leading
                )

            if !message.isFromUser { Spacer() }
        }
        .padding(.horizontal, 8)
    }
}
