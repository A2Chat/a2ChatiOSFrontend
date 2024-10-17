import Foundation
import FirebaseFirestore

struct Lobby: Encodable {
    var lobbyID: String
    var users: [String]
    var isActive: Bool

    // Convert Lobby object to a dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "lobbyID": lobbyID,
            "users": users,
            "isActive": isActive
        ]
    }
}

