import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var userUID: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Firebase Status
                if isSignedIn {
                    Text("Signed in successfully! UID: \(userUID ?? "N/A")")
                } else {
                    Text("Not signed in yet")
                }
                
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
                NavigationLink(destination: CreateView()) {
                    Text("Create")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Sign In Button
                Button(action: {
                    signOutAndSignInAnonymously() // Call the new function
                }) {
                    Text("Sign In Anonymously")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("A2Chat")
            .onAppear {
                // Check if user is already signed in
                if let user = Auth.auth().currentUser {
                    isSignedIn = true
                    userUID = user.uid
                }
            }
        }
    }
    
    // Sign Out and Create a New Anonymous User
    func signOutAndSignInAnonymously() {
        do {
            try Auth.auth().signOut() // Sign out the current user
            print("User signed out successfully")
        } catch let signOutError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }

        // Sign in anonymously
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            if let user = authResult?.user {
                print("Successfully signed in: \(user.uid)")
                userUID = user.uid // Update userUID
                isSignedIn = true
            }
        }
    }
}
