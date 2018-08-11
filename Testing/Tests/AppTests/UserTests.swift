@testable import App
import Vapor
import FluentSQLite
import XCTest

final class UserTests: XCTestCase {
    let usersName = "Test"
    let usersUsername = "test1234"
    let usersURI = "/api/users/"
    var app: Application!
    var conn: SQLiteConnection!
    
    override func setUp() {
        super.setUp()
        
        app = try! Application.testable()
        conn = try! app.newConnection(to: .sqlite).wait()
    }
    
    override func tearDown() {
        super.tearDown()
        
        conn.close()
    }
    
    func testUserCanBeSaved() throws {
        let user = User(name: usersName, username: usersUsername, password: "password")
        let createUserResponse = try app.sendRequest(to: usersURI, method: .POST, body: user, isLoggedInRequest: true)
        let receivedUser = try createUserResponse.content.decode(User.Public.self).wait()
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        let body: EmptyBody? = nil
        let getUsersResponse = try app.sendRequest(to: usersURI, method: .GET, body: body, isLoggedInRequest: true)
        let users = try getUsersResponse.content.decode([User.Public].self).wait()
        
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[1].name, usersName)
        XCTAssertEqual(users[1].username, usersUsername)
        XCTAssertEqual(users[1].id, receivedUser.id)
    }
    
    func testSingleUserCanBeRetrieved() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(usersURI)/\(user.id!)", method: .GET, body: body, isLoggedInRequest: true)
        let receivedUser = try response.content.decode(User.Public.self).wait()
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    func testAllUsersCanBeRetrieved() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: usersURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedUsers = try response.content.decode([User.Public].self).wait()
        
        XCTAssertEqual(receivedUsers.count, 2)
        XCTAssertEqual(receivedUsers[1].name, usersName)
        XCTAssertEqual(receivedUsers[1].username, usersUsername)
        XCTAssertEqual(receivedUsers[1].id, user.id)
    }
 }
