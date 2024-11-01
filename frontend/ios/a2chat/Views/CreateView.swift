import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation

struct CreateView: View {
    let lobbyFunctions = LobbyFunctions()
    let contentFunctions = ContentView()
    
    let userFunctions = UserFunctions()
    
    var userUID: String
    init(userUID: String) {
        self.userUID = userUID
    }
    
    //Textfield
    @State private var chatText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.presentationMode) var presentationMode
    
    //End button
    @State private var showAlert = false
    
    //Room code
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
            createLobby()
        }
        .navigationBarTitle(isRoomCodeVisible ? lobbyUID : "", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                showButton
            }
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
                    signOutAndReturn()
                },
                secondaryButton: .cancel()
            )
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
    
    private func createLobby() {
        lobbyFunctions.createLobby { id in
            if let lobbyId = id {
                // Use the lobby ID to add the user to the lobby
                lobbyFunctions.addUserToLobby(userUID: userUID, lobbyId: lobbyId) { success in
                    if success {
                        self.lobbyUID = lobbyId // Ensure lobbyUID is set to update view
                        print("User successfully added to the lobby with ID: \(lobbyId)")
                    } else {
                        print("Failed to add user to the lobby.")
                    }
                }
            } else {
                print("Failed to create lobby.")
            }
        }
    }

    
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
                            DispatchQueue.main.async {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}
