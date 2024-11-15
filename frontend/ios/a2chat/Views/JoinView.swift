import SwiftUI
import FirebaseAuth

//check if lobby is valid
import FirebaseFirestore


struct JoinView: View {
    let lobbyFunctions = LobbyFunctions()

    @State var otpText: String = ""
    @FocusState private var isKeyboardShowing: Bool
    
    @State private var navigateToMessageView = false
    @State private var userUID: String? = nil
    @State private var lobbyUID: String = "" // Set or get lobby UID here
    @State private var errorMessage: String? = nil // To store error message for invalid lobby
    
    var body: some View {
        NavigationView {
            VStack {
                otpInputField
                joinButton
            }
            .padding(.all)
            .frame(maxHeight: .infinity, alignment: .top)
            .toolbar { keyboardToolbar }
            .navigationDestination(isPresented: $navigateToMessageView) {
                // Proceed with navigation if userUID is not nil
                if let userUID = userUID {
                    MessageView(userUID: userUID, lobbyUID: lobbyUID) // Pass both userUID and lobbyUID
                } else {
                    EmptyView() // Or handle the case when userUID is nil
                }
            }
        }
    }
    
    /// OTP Input Field
    private var otpInputField: some View {
        HStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { index in
                OTPTextBox(index)
            }
        }
        .background(content: {
            hiddenTextField
        })
        .contentShape(Rectangle())
        .onTapGesture {
            isKeyboardShowing.toggle()
        }
        .padding(.bottom, 20)
        .padding(.top, 200)
    }
    
    /// Hidden Text Field for Input
    private var hiddenTextField: some View {
        TextField("", text: $otpText.limit(6))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            /// Hiding it out
            .frame(width: 1, height: 1)
            .opacity(0.001)
            .blendMode(.screen)
            .focused($isKeyboardShowing)
    }
    
    /// Join Button
    private var joinButton: some View {
        Button {
            joinLobbyAndNavigate()
        } label: {
            Text("Join Lobby")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.blue)
                }
        }
        .disableWithOpacity(otpText.count < 6)
    }
    
    private func joinLobbyAndNavigate() {
        // First, check if the lobby is valid
        checkIfLobbyExists { isValid in
            if isValid {
                // If valid, sign in anonymously and join the lobby
                signInAnonymouslyAndJoinLobby()
            } else {
                // Show error if the lobby is invalid
                errorMessage = "Invalid lobby. Please check the OTP and try again."
            }
        }
    }
    
    
    // TURN INTO API CALL LATER
    private func checkIfLobbyExists(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let lobbyRef = db.collection("lobbies").document(otpText)  // Assuming otpText is the lobby ID
        
        lobbyRef.getDocument { document, error in
            if let error = error {
                print("Error checking lobby: \(error.localizedDescription)")
                completion(false)
            } else {
                // Check if the document exists (lobby is valid)
                if let document = document, document.exists {
                    print("Lobby exists.")
                    completion(true)
                } else {
                    print("Lobby does not exist.")
                    completion(false)
                }
            }
        }
    }
    
    /// Sign In Anonymously and Join Lobby
    private func signInAnonymouslyAndJoinLobby() {
        // First, check if a user is already signed in
        if Auth.auth().currentUser != nil {
            // Sign out the current user
            do {
                try Auth.auth().signOut()
                print("Signed out the current user.")
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError.localizedDescription)")
                return
            }
        }
        
        // Sign in anonymously
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            if let user = authResult?.user {
                // Retrieve the ID token for the signed-in user
                user.getIDToken { idToken, error in
                    if let error = error {
                        print("Error getting ID token: \(error.localizedDescription)")
                        return
                    }
                    
                    if let idToken = idToken {
                        print("ID Token: \(idToken)") // Log the ID token
                        // Store the token in UserDefaults for later retrieval
                        UserDefaults.standard.set(idToken, forKey: "authToken")
                    }
                }
                
                // Logging successful sign-in with user ID
                print("Successfully signed in: \(user.uid)")
                
                // Update state after successful sign-in
                DispatchQueue.main.async {
                    userUID = user.uid // Update userUID
                    print("User UID after sign-in: \(String(describing: userUID))")
                    joinLobby() // Now that the user is signed in, join the lobby
                }
            }
        }
    }

    private func joinLobby() {
        // Make sure userUID is non-nil before attempting to use it
        guard let userUID = userUID else {
            print("User UID is nil")
            return
        }
        
        // Join the lobby with the entered OTP (which is used as the lobbyUID)
        lobbyUID = otpText // Set lobbyUID to the OTP text
        lobbyFunctions.addUserToLobby(userUID: userUID, lobbyId: lobbyUID) { success in
            if success {
                print("User successfully added to the lobby with ID: \(lobbyUID)")
                navigateToMessageView = true // Navigate after successful join
            } else {
                print("Failed to add user to the lobby.")
            }
        }
    }

    
    /// Keyboard Toolbar
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItem(placement: .keyboard) {
            Button("Done") {
                isKeyboardShowing.toggle()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    /// OTP Text Box
    @ViewBuilder
    private func OTPTextBox(_ index: Int) -> some View {
        ZStack {
            if otpText.count > index {
                let startIndex = otpText.startIndex
                let charIndex = otpText.index(startIndex, offsetBy: index)
                let charToString = String(otpText[charIndex])
                Text(charToString)
            } else {
                Text(" ")
            }
        }
        .frame(width: 45, height: 45)
        .background {
            /// Background Color
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.gray.opacity(0.1)) // Set background color here
                .overlay {
                    /// Highlight Current Active Box
                    let status = (isKeyboardShowing && otpText.count == index)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(status ? .black : .gray, lineWidth: status ? 2 : 0)
                        .animation(.easeInOut(duration: 0.2), value: status)
                }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Viewing Extension
extension View {
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
}

/// Binding <String> to 1 Extension
extension Binding where Value == String {
    func limit(_ length: Int) -> Self {
        if self.wrappedValue.count > length {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(length))
            }
        }
        return self
    }
}
