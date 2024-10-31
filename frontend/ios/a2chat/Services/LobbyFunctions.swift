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
    
    func createLobby(userUID: String, completion: @escaping (String) -> Void)  {
        fetchAuthConnection()
        guard let url = URL(string: "https://a2chat.mooo.com/firestore/createLobby") else {
                print("Invalid URL for lobby creation")
                return
            }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error creating lobby: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data,
                   let lobbyId = String(data: data, encoding: .utf8) {
                    print("Lobby created successfully with ID: \(lobbyId)")
                    completion(lobbyId)
                } else {
                    print("Failed to create lobby, received unexpected response.")
                }
            }.resume()
    }
    
    
    func deleteLobby(lobbyUID: String, completion: @escaping (Bool) -> Void) {
       guard let url = URL(string: "https://a2chat.mooo.com/firestore/deleteLobby") else {
           print("Invalid URL for lobby deletion")
           return
       }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = ["lobbyId": lobbyUID]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            } catch {
                print("Error serializing JSON: \(error.localizedDescription)")
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error deleting lobby: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Lobby deleted successfully with ID: \(lobbyUID)")
                } else {
                    print("Failed to delete lobby, received unexpected response.")
                }
            }.resume()
    }
}
