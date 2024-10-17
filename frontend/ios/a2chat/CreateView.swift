import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateView: View {
    var userUID: String
    
    init(userUID: String) {
        self.userUID = userUID
    }
    
    // Lobby handling
    private var lobbyService = LobbyService()
    
    // Textfield
    @State private var chatText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    // End button
    @State private var showAlert = false
    
    // Room code hide
    @State private var isRoomCodeVisible: Bool = false
    @State private var lobbyUID: String = "" // Store generated lobbyUID
    let chatTitle: String = "123456"
    
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
        .onAppear {
            createLobby() // Call createLobby when the view appears
        }
        .navigationBarTitle(isRoomCodeVisible ? chatTitle : "", displayMode: .inline)
        .toolbar {
            // Show/Hide button
            ToolbarItem(placement: .navigationBarLeading) {
                showButton
            }
            // End button
            ToolbarItem(placement: .navigationBarTrailing) {
                endButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("End Chat"),
                message: Text("Are you sure you want to delete the chat lobby?"),
                primaryButton: .destructive(Text("Delete")) {
                    signOutAndReturn() // Sign out and return to the previous view
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Show/Hide button with icon
    private var showButton: some View {
        Button(action: {
            isRoomCodeVisible.toggle() // Toggle visibility
        }) {
            HStack {
                Image(systemName: isRoomCodeVisible ? "eye.slash.fill" : "eye.fill") // Change icon based on visibility
                    .foregroundColor(.white)
            }
            .padding(.horizontal) // Match horizontal padding
            .padding(.vertical, 8) // Match vertical padding
            .background(isRoomCodeVisible ? Color.red : Color.green) // Change color based on visibility
            .cornerRadius(20) // Match corner radius to end button
            .overlay(
                RoundedRectangle(cornerRadius: 20) // Match the overlay to the button's corner radius
                    .stroke(isRoomCodeVisible ? Color.red : Color.green, lineWidth: 1) // Border color based on state
            )
            .scaleEffect(1.0) // Reset scale effect for consistency
            .animation(.easeInOut(duration: 0.2), value: isRoomCodeVisible)
        }
    }

    // End button
    private var endButton: some View {
        Button {
            showAlert = true
        } label: {
            Text("End")
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(20) // Increased corner radius for consistency
                .overlay(
                    RoundedRectangle(cornerRadius: 20) // Match the overlay to the button's corner radius
                        .stroke(Color.red, lineWidth: 1)
                )
        }
    }

    // Messages view
    private var messagesView: some View {
        ScrollView {
            ForEach(0..<20) { num in
                HStack {
                    Spacer()
                    HStack {
                        Text("ANDREW GET THE DRUGS")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            HStack { Spacer() }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .padding(.bottom, 60)
    }

    // Chat bottom bar
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            chatTextField
            sendButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // Chat text field
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

    // Send button
    private var sendButton: some View {
        Button {
            // Action for sending the message
        } label: {
            Text("Send")
                .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue)
        .cornerRadius(4)
    }

    // Sign out and return to the previous view
    private func signOutAndReturn() {
        // First, attempt to delete the lobby
        deleteLobby(lobbyUID: lobbyUID) { lobbyDeleted in
            if lobbyDeleted {
                // Then, attempt to delete the user
                deleteUser { userDeleted in
                    if userDeleted {
                        print("User with UID \(userUID) deleted successfully and signed out")
                        
                        // Ensure UI update happens on the main thread
                        DispatchQueue.main.async {
                            presentationMode.wrappedValue.dismiss() // Dismiss the current view
                        }
                    } else {
                        print("User deletion failed")
                    }
                }
            } else {
                print("Lobby deletion failed. User will not be signed out.")
            }
        }
    }
    
    private func createLobby() {
        let db = Firestore.firestore()
            
        // Create a new document with an auto-generated ID
        let newLobbyRef = db.collection("lobbies").document()
        self.lobbyUID = newLobbyRef.documentID // Get the auto-generated lobby ID
        
        let newLobby = Lobby(
            lobbyID: lobbyUID,
            users: [userUID].compactMap { $0 },
            isActive: true
        )
        
        newLobbyRef.setData(newLobby.toDictionary()) { error in
            if let error = error {
                print("Error creating lobby: \(error.localizedDescription)")
            } else {
                print("Lobby created successfully with ID: \(lobbyUID)")
                // Optionally dismiss the view or perform additional actions
            }
        }
    }
    
    func deleteUser(completion: @escaping (Bool) -> Void) {
        if let user = Auth.auth().currentUser {
            user.delete { error in
                if let error = error {
                    print("Failed to delete user: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } else {
            print("No authenticated user found")
            completion(false)
        }
    }


    func deleteLobby(lobbyUID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("lobbies").document(lobbyUID).delete { error in
            if let error = error {
                print("Failed to delete lobby: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Lobby deleted successfully")
                completion(true)
            }
        }
    }
}
