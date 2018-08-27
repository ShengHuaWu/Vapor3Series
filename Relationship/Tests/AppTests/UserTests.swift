@testable import App
import Vapor
import FluentSQLite
import XCTest

final class UserTests: XCTestCase {
    let usersName = "Test"
    let usersUsername = "test1234"
    let usersURI = "/api/users/"
    let usersPetName = "Test Pet"
    let usersPetAge = 6
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
        let receivedUsers = try getUsersResponse.content.decode([User.Public].self).wait()
        
        XCTAssertEqual(receivedUsers.count, 2)
        XCTAssertEqual(receivedUsers[1].name, usersName)
        XCTAssertEqual(receivedUsers[1].username, usersUsername)
        XCTAssertEqual(receivedUsers[1].id, receivedUser.id)
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
    
    func testUserCanBeUpdated() throws {
        let user = try User.create(name: "Vapor", username: "vapor1234", on: conn)
        let body = ["name": usersName, "username": usersUsername, "password": "password"]
        let response = try app.sendRequest(to: "\(usersURI)/\(user.id!)", method: .PUT, body: body, isLoggedInRequest: true)
        let receivedUser = try response.content.decode(User.Public.self).wait()
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    func testUserCanBeDeleted() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        let body: EmptyBody? = nil
        let _ = try app.sendRequest(to: "\(usersURI)/\(user.id!)", method: .DELETE, body: body, isLoggedInRequest: true)
        
        let response = try app.sendRequest(to: usersURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedUsers = try response.content.decode([User.Public].self).wait()
        
        XCTAssertEqual(receivedUsers.count, 1)
    }
    
    func testPetsCanBeRetrieved() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        let pet = try Pet.create(name: usersPetName, age: usersPetAge, userID: user.requireID(), on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(usersURI)/\(user.requireID())/pets", method: .GET, body: body, isLoggedInRequest: true)
        let receivedPets = try response.content.decode([Pet].self).wait()
        
        XCTAssertEqual(receivedPets.count, 1)
        XCTAssertEqual(receivedPets[0].name, usersPetName)
        XCTAssertEqual(receivedPets[0].age, usersPetAge)
        XCTAssertEqual(receivedPets[0].userID, user.id)
        XCTAssertEqual(receivedPets[0].id, pet.id)
    }
    
    static let allTests = [
        ("testUserCanBeSaved", testUserCanBeSaved),
        ("testSingleUserCanBeRetrieved", testSingleUserCanBeRetrieved),
        ("testAllUsersCanBeRetrieved", testAllUsersCanBeRetrieved),
        ("testUserCanBeUpdated", testUserCanBeUpdated),
        ("testUserCanBeDeleted", testUserCanBeDeleted),
        ("testPetsCanBeRetrieved", testPetsCanBeRetrieved) 
    ]
 }
