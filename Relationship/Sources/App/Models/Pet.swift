import Vapor
import FluentSQLite

final class Pet: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case userID = "user_id"
    }
    
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
extension Pet: Parameter {}
extension Pet: Content {}

extension Pet: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: conn) { (builder) in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

extension Pet {
    var user: Parent<Pet, User> {
        return parent(\.userID)
    }
    
    var categories: Siblings<Pet, Category, PetCategoryPivot> {
        return siblings()
    }
}
