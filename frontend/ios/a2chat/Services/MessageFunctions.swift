import Foundation
import FirebaseDatabase

class MessageFunctions: ObservableObject {
    @Published var messages: [String] = []
    private var ref: DatabaseReference! // Reference to the Firebase database
        
    init() {
            ref = Database.database().reference()
    }
    
    func sendMessage(message: String, userUID: String, timestamp: String, lobbyId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://a2chat.mooo.com/messages/\(lobbyId)") else {
            print("Invalid URL for message sending")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = ["messageContent": message, "userId": userUID, "timestamp": timestamp]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON payload: \(error)")
            completion(false)
            return
        }
        
        // Retrieve the token from UserDefaults
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            // Set the Authorization header with the token
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("No auth token found")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                print("Message sent successfully.")
                
                // Fetch updated messages after successful message send
                self.getMessages(lobbyId: lobbyId) { success in
                    if success {
                        print("Messages updated after sending.")
                        completion(true)
                    } else {
                        print("Failed to update messages after sending.")
                        completion(false)
                    }
                }
            } else {
                print("Failed to send message. HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                if let data = data, let responseMessage = String(data: data, encoding: .utf8) {
                    print("Response Message: \(responseMessage)")
                }
                completion(false)
            }
        }.resume()
    }
    
    func getMessages(lobbyId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://a2chat.mooo.com/messages/\(lobbyId)") else {
            print("Invalid URL for message sending")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Retrieve the token from UserDefaults
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            // Set the Authorization header with the token
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("No auth token found")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching messages: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                do {
                    if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = responseObject["success"] as? Bool, success,
                       let message = responseObject["message"] as? String {
                        
                        print("Success: \(message)")
                        
                        if let messagesArray = responseObject["data"] as? [[String: Any]] {
                            DispatchQueue.main.async {
                                self.messages = messagesArray.compactMap { messageDict in
                                    return messageDict["messageContent"] as? String
                                }
                                
                                print("Messages received and updated: \(self.messages)")
                                completion(true)
                            }
                        } else {
                            print("No messages found.")
                            completion(false)
                        }
                    } else {
                        print("Invalid JSON format or failed response.")
                        completion(false)
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                    completion(false)
                }
            } else {
                print("Failed to fetch messages.")
                completion(false)
            }
        }.resume()
    }
}
