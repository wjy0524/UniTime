//
//  CourseChatView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import SwiftUI

struct CourseChatView: View {

    let courseId: String
    @StateObject var vm = CourseChatViewModel()

    var body: some View {
        VStack {
            ScrollView {
                ForEach(vm.messages) { msg in
                    HStack {
                        if msg.senderId == vm.uid {
                            Spacer()
                            Text(msg.text)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        } else {
                            Text(msg.text)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack {
                TextField("Message...", text: $vm.messageText)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    Task {
                        await vm.sendMessage(courseId: courseId)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(courseId)
        .onAppear {
            vm.startListening(courseId: courseId)
        }
    }
}
