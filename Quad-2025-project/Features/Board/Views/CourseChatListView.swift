//
//  CourseChatListView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 2/21/26.
//

import SwiftUI

struct CourseChatListView: View {

    @StateObject var vm = CourseChatListViewModel()

    var body: some View {
        List(vm.chats) { chat in
            NavigationLink(chat.courseCode) {
                CourseChatView(courseId: chat.id ?? "")
            }
        }
        .navigationTitle("Course Chats")
        .onAppear {
            vm.startListening()
        }
    }
}
