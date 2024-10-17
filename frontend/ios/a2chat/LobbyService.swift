import Foundation
import FirebaseFirestore

struct LobbyService {
    private let db = Firestore.firestore()
    
    func createLobby(lobby: Lobby, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            // Add document to the "lobbies" collection
            let _ = try db.collection("lobbies").addDocument(from: lobby) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(())) // Call completion on success
                }
            }
        } catch {
            completion(.failure(error)) // Handle error if encoding fails
        }
    }
}
