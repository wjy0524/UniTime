import PhotosUI
//
//  CreatePostView.swift
//  Quad-2025-project
//
//  Created by Jaeyeon Won on 11/20/25.
//
import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: BoardViewModel

    @State var title = ""
    @State var content = ""
    @State var category = "Free"

    @State var selectedItems: [PhotosPickerItem] = []
    @State var images: [UIImage] = []

    var body: some View {
        NavigationStack {
            Form {

                TextField("Title", text: $title)
                TextEditor(text: $content).frame(height: 180)

                Picker("Category", selection: $category) {
                    ForEach(vm.categories.filter { $0 != "All" }, id: \.self) {
                        Text($0)
                    }
                }

                PhotosPicker(
                    selection: $selectedItems,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Select Images")
                }
                .onChange(of: selectedItems) {
                    Task {
                        images.removeAll()
                        for item in selectedItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                                let img = UIImage(data: data)
                            {
                                images.append(img)
                            }
                        }
                    }
                }

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(images, id: \.self) { img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task {
                            await vm.createPost(
                                title: title,
                                content: content,
                                category: category,
                                images: images
                            )
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
