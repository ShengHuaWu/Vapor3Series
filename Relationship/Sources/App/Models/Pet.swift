import Vapor
import FluentSQLite

final class Pet: Codable {
    var id: Int?
    var name: String
    var age: Int
    var userID: User.ID
    
    init(name: String, age: Int, userID: User.ID) {
        self.name = name
        self.age = age
        self.userID = userID
    }
}

extension Pet: SQLiteModel {}
extension Pet: Migration {}
extension Pet: Parameter {}
extension Pet: Content {}

extension Pet {
    var user: Parent<Pet, User> {
        return parent(\.userID)
    }
}
