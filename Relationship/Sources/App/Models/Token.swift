import Foundation
import Vapor
import FluentSQLite
import Authentication

final class Token: Codable {
    var id: Int?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: SQLiteModel {}
extension Token: Migration {}
extension Token: Content {}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 16)
        return try Token(token: random.base64EncodedString(), userID: user.requireID())
    }
}

extension Token: Authentication.Token {
    typealias UserType = User
    
    static var userIDKey: UserIDKey{
        return \Token.userID
    }
    
    static var tokenKey: TokenKey {
        return \Token.token
    }
}
