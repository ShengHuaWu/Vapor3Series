@testable import App
import FluentSQLite
import Crypto

extension User {
    static func create(name: String, username: String, on conn: SQLiteConnection) throws -> User {
        let password = try BCrypt.hash("password")
        let user = User(name: name, username: username, password: password)
        return try user.save(on: conn).wait()
    }
}
