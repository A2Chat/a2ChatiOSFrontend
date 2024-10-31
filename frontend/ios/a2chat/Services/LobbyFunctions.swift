import Foundation

class LobbyFunctions {
    private func fetchAuthConnection() {
        guard let url = URL(string: "https://a2chat.mooo.com/auth/checkConnection") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data recieved")
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                print("Response JSON: \(jsonResponse)")
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }
    
    
    func createLobby(userUID: String, completion: @escaping (String) -> Void) {
        guard let createLobbyURL = URL(string: "https://a2chat.mooo.com/firestore/createLobby") else {
            print("Invalid URL for lobby creation")
            return
        }
        
        var request = URLRequest(url: createLobbyURL)
        request.httpMethod = "POST"  // Assuming POST to create a lobby

        // Call the create lobby API
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error creating lobby: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to read data"
                    print("Response Data: \(responseString)")
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        do {
                            // Parse JSON response to extract lobby ID
                            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                               let lobbyId = jsonResponse["code"] as? String {
                                print("Lobby created successfully with ID: \(lobbyId)")
                                
                                // Proceed to add the user to the lobby
                                guard let addUserURL = URL(string: "https://a2chat.mooo.com/firestore/addUserToLobby") else {
                                    print("Invalid URL for adding user to lobby")
                                    return
                                }
                                
                                var addUserRequest = URLRequest(url: addUserURL)
                                addUserRequest.httpMethod = "PUT"
                                addUserRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                
                                let payload: [String: Any] = ["lobbyID": lobbyId, "UID": userUID]
                                addUserRequest.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
                                
                                URLSession.shared.dataTask(with: addUserRequest) { addUserData, addUserResponse, addUserError in
                                    if let addUserError = addUserError {
                                        print("Error adding user to lobby: \(addUserError.localizedDescription)")
                                        return
                                    }
                                    
                                    if let addUserHttpResponse = addUserResponse as? HTTPURLResponse {
                                        print("HTTP Status Code for addUserToLobby: \(addUserHttpResponse.statusCode)")
                                        
                                        if addUserHttpResponse.statusCode == 200 {
                                            print("User added to lobby successfully.")
                                            completion(lobbyId)  // Return the lobby ID
                                        } else {
                                            print("Failed to add user to lobby.")
                                        }
                                    } else {
                                        print("Unable to cast response to HTTPURLResponse for addUserToLobby.")
                                    }
                                }.resume()
                            } else {
                                print("Failed to decode lobby ID from response.")
                            }
                        } catch {
                            print("Error parsing JSON: \(error)")
                        }
                    } else {
                        print("Failed to create lobby, received unexpected response.")
                    }
                }
            } else {
                print("Unable to cast response to HTTPURLResponse.")
            }
        }.resume()
    }


    func deleteLobby(lobbyUID: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://a2chat.mooo.com/firestore/deleteLobby") else {
            print("Invalid URL for lobby deletion")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Payload with correct key
        let payload: [String: Any] = ["lobbyId": lobbyUID]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting lobby: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Unable to cast response to HTTPURLResponse.")
                completion(false)
                return
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                print("Lobby deleted successfully with ID: \(lobbyUID)")
                completion(true)
            } else {
                print("Failed to delete lobby, received unexpected response: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response Data: \(responseString)")
                }
                completion(false)
            }
        }.resume()
    }
}
