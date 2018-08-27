@testable import App
import Vapor
import FluentSQLite
import XCTest

final class PetTests: XCTestCase {
    let petsName = "Test Pet"
    let petsAge = 10
    let petsUserID = 1
    let petsURI = "/api/pets/"
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
    
    func testPetCanBeSaved() throws {
        let pet = Pet(name: petsName, age: petsAge, userID: petsUserID)
        let createPetResponse = try app.sendRequest(to: petsURI, method: .POST, body: pet, isLoggedInRequest: true)
        let receivedPet = try createPetResponse.content.decode(Pet.self).wait()
        
        XCTAssertEqual(receivedPet.name, petsName)
        XCTAssertEqual(receivedPet.age, petsAge)
        XCTAssertEqual(receivedPet.userID, petsUserID)
        XCTAssertNotNil(receivedPet.id)
        
        let body: EmptyBody? = nil
        let getPetsResponse = try app.sendRequest(to: petsURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedPets = try getPetsResponse.content.decode([Pet].self).wait()
        
        XCTAssertEqual(receivedPets.count, 1)
        XCTAssertEqual(receivedPets[0].name, petsName)
        XCTAssertEqual(receivedPets[0].age, petsAge)
        XCTAssertEqual(receivedPets[0].userID, petsUserID)
        XCTAssertEqual(receivedPets[0].id, receivedPet.id)
    }
    
    func testSinglePetCanBeRetrieved() throws {
        let pet = try Pet.create(name: petsName, age: petsAge, userID: petsUserID, on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())", method: .GET, body: body, isLoggedInRequest: true)
        let receivedPet = try response.content.decode(Pet.self).wait()
        
        XCTAssertEqual(receivedPet.name, petsName)
        XCTAssertEqual(receivedPet.age, petsAge)
        XCTAssertEqual(receivedPet.userID, petsUserID)
        XCTAssertEqual(receivedPet.id, pet.id)
    }
    
    func testAllPetsCanBeRetrieved() throws {
        let pet = try Pet.create(name: petsName, age: petsAge, userID: petsUserID, on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: petsURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedPets = try response.content.decode([Pet].self).wait()
        
        XCTAssertEqual(receivedPets.count, 1)
        XCTAssertEqual(receivedPets[0].name, petsName)
        XCTAssertEqual(receivedPets[0].age, petsAge)
        XCTAssertEqual(receivedPets[0].userID, petsUserID)
        XCTAssertEqual(receivedPets[0].id, pet.id)
    }
    
    func testPetCanBeUpdated() throws {
        let pet = try Pet.create(name: "Vapor", age: 8, userID: petsUserID, on: conn)
        let updatedPet = Pet(name: petsName, age: petsAge, userID: petsUserID)
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())", method: .PUT, body: updatedPet, isLoggedInRequest: true)
        let receivedPet = try response.content.decode(Pet.self).wait()
        
        XCTAssertEqual(receivedPet.name, petsName)
        XCTAssertEqual(receivedPet.age, petsAge)
        XCTAssertEqual(receivedPet.userID, petsUserID)
        XCTAssertEqual(receivedPet.id, pet.id)
    }
    
    func testPetCanBeDeleted() throws {
        let pet = try Pet.create(name: petsName, age: petsAge, userID: petsUserID, on: conn)
        let body: EmptyBody? = nil
        let _ = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())", method: .DELETE, body: body, isLoggedInRequest: true)
        
        let response = try app.sendRequest(to: petsURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedPets = try response.content.decode([Pet].self).wait()
        
        XCTAssertEqual(receivedPets.count, 0)
    }
    
    func testUserCanBeRetrieved() throws {
        let pet = try Pet.create(name: petsName, age: petsAge, userID: petsUserID, on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())/user", method: .GET, body: body, isLoggedInRequest: true)
        let receivedUser = try response.content.decode(User.Public.self).wait()
        
        XCTAssertEqual(receivedUser.name, "Admin")
        XCTAssertEqual(receivedUser.username, "admin")
        XCTAssertEqual(receivedUser.id, petsUserID)
    }
}
