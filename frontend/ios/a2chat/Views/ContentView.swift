import SwiftUI
import FirebaseAuth
import Foundation

struct ContentView: View {
    @State private var navigateToMessageView = false // State for navigation
    @State private var userUID: String? = nil
    @State private var lobbyUID: String = "" // Make lobbyUID a @State property to allow updates
    
    let lobbyFunctions = LobbyFunctions()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Join Button
                NavigationLink(destination: JoinView()) {
                    Text("Join")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Create Button
                Button(action: {
                    signInAnonymously() // Sign in first
                }) {
                    Text("Create")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("A2Chat")
            .onAppear {
                // Check if user is already signed in
                if let user = Auth.auth().currentUser {
                    userUID = user.uid
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $navigateToMessageView) {
                if let userUID = userUID {
                    MessageView(userUID: userUID, lobbyUID: lobbyUID) // Pass lobbyUID here
                } else {
                    // Handle the case where userUID is nil, if necessary
                    Text("User not signed in.")
                }
            }
        }
    }
    
    private func createLobby() {
        // Ensure that the user is signed in before creating a lobby
        guard let userUID = userUID else {
            print("User is not signed in.")
            return
        }
        
        lobbyFunctions.createLobby { id in
            print("Lobby creation response received: \(String(describing: id))")
            if let lobbyId = id {
                lobbyFunctions.addUserToLobby(userUID: userUID, lobbyId: lobbyId) { success in
                    print("Adding user to lobby...")
                    if success {
                        DispatchQueue.main.async {
                            lobbyUID = lobbyId // This is now valid with @State
                            print("User successfully added to the lobby with ID: \(lobbyId)")
                            navigateToMessageView = true // Trigger navigation once lobby is created
                        }
                    } else {
                        print("Failed to add user to the lobby.")
                    }
                }
            }
        }
    }
    
    func signInAnonymously() {
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
                    createLobby() // Now that the user is signed in, create the lobby
                }
            }
        }
    }

}
