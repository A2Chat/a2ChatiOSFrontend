import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation
import FirebaseDatabase

struct MessageData: Identifiable, Equatable {
    let id: String // Use the message ID from Firebase if available
    let userid: String
    let messageContent: String
    let fromUser: Bool
    
    // Conformance to Equatable
    static func ==(lhs: MessageData, rhs: MessageData) -> Bool {
        return lhs.id == rhs.id && lhs.userid == rhs.userid && lhs.messageContent == rhs.messageContent && lhs.fromUser == rhs.fromUser
    }
}

struct MessageView: View {
    private var databaseRef = Database.database().reference()
    @State private var currentListOfMessages : [MessageData] = []
    
    let lobbyFunctions = LobbyFunctions()
    let userFunctions = UserFunctions()
    let messageFunctions = MessageFunctions()
    
    var userUID: String
    var lobbyUID: String
    
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
            currentListOfMessages = setupFirebaseListener()
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
        ScrollViewReader { proxy in
            ScrollView {
                if currentListOfMessages.isEmpty {
                    Text("No messages yet")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(currentListOfMessages) { message in
                        HStack {
                            if message.fromUser {
                                Spacer() // Align to the right if from the user
                                HStack {
                                    VStack(alignment: .trailing) {
                                        Text("[\(userUID)]") // Display current user's UID above message
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                        Text(message.messageContent)
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 4)
                            } else {
                                HStack {
                                    VStack(alignment: .leading) {
                                        // Display the other user's UID above message
                                        Text("[\(message.userid)]")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                        Text(message.messageContent)
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 4)
                                Spacer()
                            }
                        }
                        .id(message.id)
                    }
                        // Add a dummy bottom marker to scroll to
                       Color.clear
                           .id("bottomMarker")
               }
               HStack { Spacer() }
           }
           .background(Color(.init(white: 0.95, alpha: 1)))
           .padding(.bottom, 60)
           .onChange(of: currentListOfMessages) {
               // Scroll to the bottom when messages change
               withAnimation {
                   proxy.scrollTo("bottomMarker", anchor: .bottom)
               }
           }
           .onChange(of: isTextFieldFocused) {
               // Log when the TextField focus changes
               if isTextFieldFocused {
                   print("TextField is focused (isTextFieldFocused = true)")
               } else {
                   print("TextField is unfocused (isTextFieldFocused = false)")
               }
               // Scroll to the bottom when the text field is tapped
               withAnimation {
                   proxy.scrollTo("bottomMarker", anchor: .bottom)
               }
           }
        }
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
            // Only send if the message is not empty
            guard !chatText.isEmpty else { return }
            
            let timestamp = ISO8601DateFormatter().string(from: Date())
            messageFunctions.sendMessage(message: chatText, userUID: userUID, timestamp: timestamp, lobbyId: lobbyUID) { success in
                if success {
                    DispatchQueue.main.async {
                        chatText = "" // Clear the text field only after sending the message
                        isTextFieldFocused = false // Dismiss the keyboard
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

    
    private func setupFirebaseListener() -> [MessageData] {
        let lobbyRef = databaseRef.child("messages").child(lobbyUID)
        lobbyRef.observe(DataEventType.value, with: { snapshot in
            var snapshotMessageList: [MessageData] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let message = childSnapshot.childSnapshot(forPath: "messageContent").value as? String,
                   let uid = childSnapshot.childSnapshot(forPath: "userId").value as? String {
                    let fromUser = uid == userUID
                    let msgId = childSnapshot.key
                    let messageData = MessageData(id: msgId, userid: uid, messageContent: message, fromUser: fromUser)
                    snapshotMessageList.append(messageData)
                }
            }
            
            // Update the message list
            print("Messages: \(snapshotMessageList)")
            self.currentListOfMessages = snapshotMessageList
        })
        return currentListOfMessages
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
