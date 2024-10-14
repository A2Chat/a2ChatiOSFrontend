import SwiftUI
import FirebaseAuth // Delete this line if not using Firebase Authentication

struct ContentView: View {
    @State private var isSignedIn = false // Delete this line if not using Firebase Authentication

    var body: some View {
        NavigationView {
            VStack(spacing: 20) { // Added spacing between elements
                
                // Firebase Status
                if isSignedIn { // Delete this block if not using Firebase Authentication
                    Text("Signed in successfully!")
                } else {
                    Text("Not signed in yet")
                }
                
                // Join Button
                NavigationLink(destination: JoinView()) {
                    Text("Join")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity) // Make button full width
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Create Button
                NavigationLink(destination: CreateView()) {
                    Text("Create")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity) // Make button full width
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Sign In Button
                Button(action: {
                    signInAnonymously() // Delete this line and button block if not using Firebase Authentication
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
            .navigationTitle("A2Chat") // Title for the navigation bar
        }
    }
    
    // Firebase Anonymous Sign In Method
    func signInAnonymously() { // Delete this entire function if not using Firebase Authentication
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            print("Successfully signed in: \(authResult?.user.uid ?? "No UID")")
            isSignedIn = true
        }
    }
}
