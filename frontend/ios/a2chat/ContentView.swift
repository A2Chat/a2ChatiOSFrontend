import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var showMenu = false
    @State private var navigateToCreateView = false // State for navigation
    
    @State private var userUID: String? = nil
    
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
                    signInAnonymously() // Sign in before navigating
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
                    isSignedIn = true
                    userUID = user.uid
                }
            }
            .navigationDestination(isPresented: $navigateToCreateView) {
                if let userUID = userUID {
                    CreateView(userUID: userUID) // Safely pass the unwrapped value
                } else {
                    // Handle the case where userUID is nil, if necessary
                }
            }
        }
    }
    
    func signInAnonymously() {
        // Sign in anonymously
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            if let user = authResult?.user {
                // Logging successful sign-in with user ID
                print("Successfully signed in: \(user.uid)")
                
                // Update state after successful sign-in
                DispatchQueue.main.async {
                    userUID = user.uid // Update userUID
                    isSignedIn = true
                    navigateToCreateView = true // Trigger navigation
                }
            }
        }
    }
}
