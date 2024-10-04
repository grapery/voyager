//
//  StoryView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine

struct StoryView: View {
    @State var viewModel: StoryViewModel
    @State private var isEditing: Bool = false
    @State public var storyId: Int64
    var userId: Int64
    init(storyId: Int64,userId:Int64) {
        self.storyId = storyId
        self.userId = userId
        self.viewModel = StoryViewModel(storyId: storyId)
    }
    
    var body: some View {
        VStack{
            HStack{
                KFImage(URL(string: (self.viewModel.story?.storyInfo.avatar)!))
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
                
                Text((self.viewModel.story?.storyInfo.name)!)
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .blur(radius: CGFloat(0.5))
            Spacer()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let story = viewModel.story {
                        storyContent(story)
                    } else {
                        Text("Failed to load story")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Story Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task{
                            await viewModel.updateStory()
                        }
                    }
                    isEditing.toggle()
                }
            }
        }
        .onAppear {
            Task{
                await viewModel.fetchStory()
            }
        }
    }
    
    @ViewBuilder
    private func storyContent(_ story: Story) -> some View {
        if story.storyInfo.rootBoardID == 0 {
            VStack{
                
            }
        }
        
    }
}

struct StoryBoardCellView: View{
    var board: StoryBoard?
    var userId: Int64
    var groupId: Int64
    var storyId: Int64
    var body: some View{
        return VStack{}
    }
}



extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}



