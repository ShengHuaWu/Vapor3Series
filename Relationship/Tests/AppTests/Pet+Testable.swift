@testable import App
import FluentSQLite

extension Pet {
    static func create(name: String, age: Int, userID: User.ID, on conn: SQLiteConnection) throws -> Pet {
        let pet = Pet(name: name, age: age, userID: userID)
        return try pet.save(on: conn).wait()
    }
}
