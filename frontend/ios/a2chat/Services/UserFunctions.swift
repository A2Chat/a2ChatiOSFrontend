import Foundation

class UserFunctions {
    func deleteUser(with uid: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://a2chat.mooo.com/auth/deleteUser") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE" // Set the HTTP method to DELETE
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set content type to JSON

        // Create the JSON body with the UID
        let jsonBody: [String: Any] = ["uid": uid]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        } catch {
            print("Error creating JSON body: \(error)")
            completion(false) // Ensure completion is called on error
            return
        }

        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting user: \(error)")
                completion(false) // Completion on error
                return
            }

            guard let data = data else {
                print("No data received")
                completion(false) // Completion if no data
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                print("Response JSON: \(jsonResponse)")
                completion(true) // Call completion with success
            } catch {
                print("Error parsing JSON: \(error)")
                completion(false) // Completion on parsing error
            }
        }
        
        task.resume() // Start the network task
    }
}