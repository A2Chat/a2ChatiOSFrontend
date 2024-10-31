import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation

struct CreateView: View {
    let lobbyFunctions = LobbyFunctions()
    let userFunctions = UserFunctions()
    
    var userUID: String
    init(userUID: String) {
        self.userUID = userUID
    }
    
    // Textfield
    @State private var chatText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    // End button
    @State private var showAlert = false
    
    // Room code hide
    @State private var isRoomCodeVisible: Bool = false
    @State private var lobbyUID: String = "" // Store generated lobbyUID
    
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
            createLobby(userUID : userUID)
        }
        .navigationBarTitle(isRoomCodeVisible ? lobbyUID : "", displayMode: .inline)
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
    
    private func createLobby() {
        lobbyFunctions.createLobby { id in
            lobbyUID = id
        }
    }
    
    // Sign out and return to the previous view
    private func signOutAndReturn() {
        print("Attempting to delete the lobby...")
        lobbyFunctions.deleteLobby(lobbyUID: lobbyUID) { lobbyDeleted in
            print("Lobby deleted: \(lobbyDeleted)")
            if lobbyDeleted {
                if let user = Auth.auth().currentUser {
                    print("Current user found: \(user.uid)")
                    userFunctions.deleteUser(with: user.uid) { userDeleted in
                        print("User deletion success: \(userDeleted)")
                        if userDeleted {
                            print("User with UID \(user.uid) deleted successfully and signed out")
                            DispatchQueue.main.async {
                                print("Dismissing the current view...")
                                presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            print("User deletion failed")
                        }
                    }
                } else {
                    print("No current user found. User will not be deleted.")
                }
            } else {
                print("Lobby deletion failed. User will not be signed out.")
            }
        }
    }
}
