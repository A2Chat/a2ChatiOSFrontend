import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) { // Added spacing between elements
                
                // Join Button
                NavigationLink(destination: JoinView()) { // Replace with an actual integer
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
            }
            .padding()
            .navigationTitle("A2Chat") // Title for the navigation bar
        }
    }
}
