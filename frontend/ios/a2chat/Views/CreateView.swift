import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation
struct CreateView: View {
    let lobbyFunctions = LobbyFunctions()
    let userFunctions = UserFunctions()
    
    var userUID: String
    var lobbyUID: String
    
    //textbox
    @State private var chatText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    //code
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

    private func signOutAndReturn() {
        print("Attempting to remove user from the lobby...")
        lobbyFunctions.removeUsersFromLobby(lobbyUID: lobbyUID, userUID: Auth.auth().currentUser?.uid ?? "") { userRemoved, message in
            print("User removed from lobby: \(userRemoved), message: \(message ?? "No message")")
            
            if userRemoved {
                if let user = Auth.auth().currentUser {
                    print("Current user found: \(user.uid), proceeding with user deletion...")
                    userFunctions.deleteUser(with: user.uid) { userDeleted in
                        print("User deletion success: \(userDeleted)")
                        if userDeleted {
                            // Set the state to trigger navigation to ContentView
                            DispatchQueue.main.async {
                                navigateBackToContentView = true
                            }
                        }
                    }
                } else {
                    print("No current user found, cannot delete user.")
                }
            } else {
                print("Failed to remove user from lobby, user deletion will not proceed.")
            }
        }
    }

}
