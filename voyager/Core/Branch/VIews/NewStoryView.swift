//
//  NewStoryView.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI

struct NewStoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: StoryViewModel
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // 新增的状态变量
    @State private var name: String = ""
    @State private var title: String = ""
    @State private var shortDesc: String = ""
    @State private var origin: String = ""
    @State private var isAIGen: Bool = false
    @State private var storyDescription: String = ""
    @State private var refImage: UIImage?
    @State private var negativePrompt: String = ""
    @State private var background: String = ""
    
    @State private var showImagePicker: Bool = false
    var groupId:Int64
    init(groupId: Int64, userId: Int64) {
        self._viewModel = StateObject(wrappedValue: StoryViewModel(storyId: -1, userId: userId))
        self.groupId = groupId
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Required Information")) {
                    TextField("Name", text: $name)
                    TextField("Title", text: $title)
                    TextField("Short Description", text: $shortDesc)
                    TextEditor(text: $origin)
                        .frame(height: 100)
                }
                
                Section(header: Text("AI Generation")) {
                    Toggle("Generate with AI", isOn: $isAIGen)
                }
                
                Section(header: Text("Optional Information")) {
                    TextField("Story Description", text: $storyDescription)
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text(refImage == nil ? "Add Reference Image" : "Change Reference Image")
                    }
                    
                    if let image = refImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    TextField("Negative Prompt", text: $negativePrompt)
                    TextField("Background", text: $background)
                }
                
                Section {
                    Button(action: createStory) {
                        Text("Create Story")
                    }
                }
            }
            .navigationTitle("New Story")
            .navigationBarItems(leading: cancelButton)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $refImage)
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func createStory() {
        // Validate required fields
        guard !name.isEmpty else {
            showAlert(message: "Please enter a name")
            return
        }
        guard !title.isEmpty else {
            showAlert(message: "Please enter a title")
            return
        }
        guard !shortDesc.isEmpty else {
            showAlert(message: "Please enter a short description")
            return
        }
        guard !origin.isEmpty else {
            showAlert(message: "Please enter the story content")
            return
        }
        
        Task {
            do {
                // Update viewModel.story with the input data
                viewModel.story?.storyInfo.name = name
                viewModel.story?.storyInfo.title = title
                viewModel.story?.storyInfo.desc = shortDesc
                viewModel.story?.storyInfo.origin = origin
                viewModel.story?.storyInfo.isAiGen = isAIGen
                viewModel.story?.storyInfo.params.storyDescription = storyDescription
                viewModel.story?.storyInfo.params.negativePrompt = negativePrompt
                viewModel.story?.storyInfo.params.background = background
                
                // Handle refImage if needed (you might need to upload it separately)
                
                await viewModel.CreateStory(groupId: self.groupId)
                presentationMode.wrappedValue.dismiss()
            } catch {
                showAlert(message: "Failed to create story: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct NewStoryView_Previews: PreviewProvider {
    static var previews: some View {
        NewStoryView(groupId: 1, userId: 1)
    }
}
