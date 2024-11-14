import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation
import FirebaseDatabase

struct MessageData: Identifiable {
    let id: String // Use the message ID from Firebase if available
    let messageContent: String
    let fromUser: Bool
}

struct MessageView: View {
    private var databaseRef = Database.database().reference()
    @State private var currentListOfMessages : [MessageData] = []
    
    let lobbyFunctions = LobbyFunctions()
    let userFunctions = UserFunctions()
    let messageFunctions = MessageFunctions()
    
    var userUID: String
    var lobbyUID: String
    
    //chat messages
    @StateObject private var viewModel = MessageFunctions()
    
    //textbox
    @State private var chatText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    //lobby code
    @State private var showAlert = false
    @State private var isRoomCodeVisible: Bool = false
    
    init(userUID: String, lobbyUID: String) {
        self.userUID = userUID
        self.lobbyUID = lobbyUID
    }
    
    //destination after finished
    @State private var navigateBackToContentView = false
    
    var body: some View {
        ZStack {
            messagesView
            VStack {
                Spacer()
                chatBottomBar
                    .background(Color.white)
            }
        }
        .padding(.top, 16)
        .navigationBarTitle(isRoomCodeVisible ? (lobbyUID) : "", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                showButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                endButton
            }
        }
        .onAppear {
            viewModel.getMessages(lobbyId: lobbyUID) { success in
                if success {
                    print("Messages fetched successfully.")
                }
            }
            setupFirebaseListener()
        }
        .onReceive(viewModel.$messages) { _ in
            print("Messages updated in view: \(viewModel.messages)")
        }
        .navigationBarBackButtonHidden(true) // Hide the back button here
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("End Chat"),
                message: Text("Are you sure you want to delete the chat lobby?"),
                primaryButton: .destructive(Text("Delete")) {
                    signOutAndReturn()
                },
                secondaryButton: .cancel()
            )
        }
        .navigationDestination(isPresented: $navigateBackToContentView) {
            ContentView() // Navigate back to ContentView after deletion
        }
    }
    
    private var showButton: some View {
        Button(action: {
            isRoomCodeVisible.toggle()
            print("isRoomCodeVisible toggled to: \(isRoomCodeVisible)")
        }) {
            HStack {
                Image(systemName: isRoomCodeVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isRoomCodeVisible ? Color.red : Color.green)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isRoomCodeVisible ? Color.red : Color.green, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isRoomCodeVisible)
        }
    }
    
    private var endButton: some View {
        Button {
            showAlert = true
        } label: {
            Text("End")
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red, lineWidth: 1)
                )
        }
    }
    
    private var messagesView: some View {
        ScrollView {
            if currentListOfMessages.isEmpty {
                Text("No messages yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(currentListOfMessages) { message in
                    HStack {
                        // Check if the message is from the user or another user
                        if message.fromUser {
                            Spacer() // Align to the right if from the user
                            HStack {
                                Text(message.messageContent)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue) // Green background for the user's messages
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                        } else {
                            // Align to the left if the message is not from the user
                            HStack {
                                Text(message.messageContent)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green) // Blue background for other users' messages
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                            Spacer() // Ensure it aligns to the left
                        }
                    }
                }
            }
            HStack { Spacer() }
        }
        .background(Color(.init(white: 0.95, alpha: 1))) // Slight background for the chat view
        .padding(.bottom, 60)
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            chatTextField
            sendButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var chatTextField: some View {
        TextField("Text Message", text: $chatText)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isTextFieldFocused ? Color.blue : Color.gray, lineWidth: isTextFieldFocused ? 2 : 1)
            )
            .cornerRadius(10)
            .focused($isTextFieldFocused)
    }
    
    private var sendButton: some View {
        Button {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            messageFunctions.sendMessage(message: chatText, userUID: userUID, timestamp: timestamp, lobbyId: lobbyUID) { success in
                if success {
                    DispatchQueue.main.async {
                        chatText = "" // Clear the text field
                    }
                } else {
                    print("Failed to send message.")
                }
            }
        } label: {
            Text("Send")
                .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue)
        .cornerRadius(4)
    }
    
    private func setupFirebaseListener() {
        let lobbyRef = databaseRef.child("messages").child(lobbyUID)
        lobbyRef.observe(DataEventType.value, with: { snapshot in
            var snapshotMessageList: [MessageData] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let message = childSnapshot.childSnapshot(forPath: "messageContent").value as? String,
                   let uid = childSnapshot.childSnapshot(forPath: "userId").value as? String {
                    let fromUser = uid == userUID
                    let msgId = childSnapshot.key
                    let messageData = MessageData(id: msgId, messageContent: message, fromUser: fromUser)
                    snapshotMessageList.append(messageData)
                }
            }
            
            // Update the message list
            print("Messages: \(snapshotMessageList)")
            self.currentListOfMessages = snapshotMessageList
        })
    }

    private func signOutAndReturn() {
        print("Attempting to remove user from the lobby...")
        lobbyFunctions.batchUserEndChat(lobbyUID: lobbyUID, userUID: Auth.auth().currentUser?.uid ?? "") { userRemoved, message in
            print("User removed from lobby: \(userRemoved), message: \(message ?? "No message")")
            
            if userRemoved {
                    print("User deletion success")
                        // Set the state to trigger navigation to ContentView
                        DispatchQueue.main.async {
                        navigateBackToContentView = true
                    }
                } else {
                    print("No current user found, cannot delete user.")
            }
        }
    }
}
