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
    
    func createLobby(completion: @escaping (String?) -> Void) {
        guard let createLobbyURL = URL(string: "https://a2chat.mooo.com/firestore/createLobby") else {
            print("Invalid URL for lobby creation")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: createLobbyURL)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error creating lobby: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let data = data {
                    do {
                        // Parse JSON response to extract lobby ID
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let lobbyId = jsonResponse["code"] as? String {
                            print("Lobby created successfully with ID: \(lobbyId)")
                            completion(lobbyId)
                        } else {
                            print("Failed to decode lobby ID from response.")
                            completion(nil)
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                        completion(nil)
                    }
                } else {
                    print("No data received in response.")
                    completion(nil)
                }
            } else {
                print("Failed to create lobby, received unexpected response.")
                completion(nil)
            }
        }.resume()
    }

    func addUserToLobby(userUID: String, lobbyId: String, completion: @escaping (Bool) -> Void) {
        guard let addUserURL = URL(string: "https://a2chat.mooo.com/firestore/addUserToLobby") else {
            print("Invalid URL for adding user to lobby")
            completion(false)
            return
        }
        
        var request = URLRequest(url: addUserURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = ["lobbyID": lobbyId, "UID": userUID]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON payload: \(error)")
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error adding user to lobby: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("User added to lobby successfully.")
                completion(true)
            } else {
                print("Failed to add user to lobby.")
                completion(false)
            }
        }.resume()
    }

    func removeUsersFromLobby(lobbyUID: String, userUID: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "https://a2chat.mooo.com/firestore/removeUsersFromLobby") else {
            print("Invalid URL for user removal")
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Payload with lobby and user IDs
        let payload: [String: Any] = ["lobbyID": lobbyUID, "UID": userUID]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            completion(false, "Error serializing JSON")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error removing user from lobby: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Unable to cast response to HTTPURLResponse.")
                completion(false, "Invalid response format")
                return
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                if let data = data,
                   let responseDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = responseDict["message"] as? String {
                    print("Success: \(message)")
                    completion(true, message)
                } else {
                    completion(true, "User removed successfully")
                }
            } else {
                print("Failed to remove user, unexpected response: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response Data: \(responseString)")
                    completion(false, responseString)
                } else {
                    completion(false, "Unexpected server response")
                }
            }
        }.resume()
    }

}
