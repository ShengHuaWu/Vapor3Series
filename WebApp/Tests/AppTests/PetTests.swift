@testable import App
import Vapor
import FluentSQLite
import XCTest

final class PetTests: XCTestCase {
    typealias Category = App.Category
    
    let petsName = "Test Pet"
    let petsAge = 10
    let petsURI = "/api/pets/"
    let petsUserName = "Test"
    let petsUserUsername = "test1234"
    let petsCategoryName = "test category"
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
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet(name: petsName, age: petsAge, userID: user.requireID())
        let createPetResponse = try app.sendRequest(to: petsURI, method: .POST, body: pet, isLoggedInRequest: true)
        let receivedPet = try createPetResponse.content.decode(Pet.self).wait()
        
        XCTAssertEqual(receivedPet.name, petsName)
        XCTAssertEqual(receivedPet.age, petsAge)
        XCTAssertEqual(receivedPet.userID, user.id)
        XCTAssertNotNil(receivedPet.id)
        
        let body: EmptyBody? = nil
        let getPetsResponse = try app.sendRequest(to: petsURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedPets = try getPetsResponse.content.decode([Pet].self).wait()
        
        XCTAssertEqual(receivedPets.count, 1)
        XCTAssertEqual(receivedPets[0].name, petsName)
        XCTAssertEqual(receivedPets[0].age, petsAge)
        XCTAssertEqual(receivedPets[0].userID, user.id)
        XCTAssertEqual(receivedPets[0].id, receivedPet.id)
    }
    
    func testSinglePetCanBeRetrieved() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: petsName, age: petsAge, userID: user.requireID(), on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())", method: .GET, body: body, isLoggedInRequest: true)
        let receivedPet = try response.content.decode(Pet.self).wait()
        
        XCTAssertEqual(receivedPet.name, petsName)
        XCTAssertEqual(receivedPet.age, petsAge)
        XCTAssertEqual(receivedPet.userID, user.id)
        XCTAssertEqual(receivedPet.id, pet.id)
    }
    
    func testAllPetsCanBeRetrieved() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: petsName, age: petsAge, userID: user.requireID(), on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: petsURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedPets = try response.content.decode([Pet].self).wait()
        
        XCTAssertEqual(receivedPets.count, 1)
        XCTAssertEqual(receivedPets[0].name, petsName)
        XCTAssertEqual(receivedPets[0].age, petsAge)
        XCTAssertEqual(receivedPets[0].userID, user.id)
        XCTAssertEqual(receivedPets[0].id, pet.id)
    }
    
    func testPetCanBeUpdated() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: "Vapor", age: 8, userID: user.requireID(), on: conn)
        let updatedPet = try Pet(name: petsName, age: petsAge, userID: user.requireID())
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())", method: .PUT, body: updatedPet, isLoggedInRequest: true)
        let receivedPet = try response.content.decode(Pet.self).wait()
        
        XCTAssertEqual(receivedPet.name, petsName)
        XCTAssertEqual(receivedPet.age, petsAge)
        XCTAssertEqual(receivedPet.userID, user.id)
        XCTAssertEqual(receivedPet.id, pet.id)
    }
    
    func testPetCanBeDeleted() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: petsName, age: petsAge, userID: user.requireID(), on: conn)
        let body: EmptyBody? = nil
        let _ = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())", method: .DELETE, body: body, isLoggedInRequest: true)
        
        let response = try app.sendRequest(to: petsURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedPets = try response.content.decode([Pet].self).wait()
        
        XCTAssertEqual(receivedPets.count, 0)
    }
    
    func testUserCanBeRetrieved() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: petsName, age: petsAge, userID: user.requireID(), on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())/user", method: .GET, body: body, isLoggedInRequest: true)
        let receivedUser = try response.content.decode(User.Public.self).wait()
        
        XCTAssertEqual(receivedUser.name, petsUserName)
        XCTAssertEqual(receivedUser.username, petsUserUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    func testPetCategoryPivotCanBeSaved() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: petsName, age: petsAge, userID: user.requireID(), on: conn)
        let category = try Category.create(name: petsCategoryName, on: conn)
        let body: EmptyBody? = nil
        let _ = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())/categories/\(category.requireID())", method: .POST, body: body, isLoggedInRequest: true)
        
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())/categories", method: .GET, body: body, isLoggedInRequest: true)
        let receivedCategories = try response.content.decode([Category].self).wait()
        
        XCTAssertEqual(receivedCategories.count, 1)
        XCTAssertEqual(receivedCategories[0].name, petsCategoryName)
        XCTAssertEqual(receivedCategories[0].id, category.id)
    }
    
    func testCategoriesCanBeRetrieved() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: petsName, age: petsAge, userID: user.requireID(), on: conn)
        let category = try Category.create(name: petsCategoryName, on: conn)
        let _ = try pet.categories.attach(category, on: conn).wait()
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())/categories", method: .GET, body: body, isLoggedInRequest: true)
        let receivedCategories = try response.content.decode([Category].self).wait()
        
        XCTAssertEqual(receivedCategories.count, 1)
        XCTAssertEqual(receivedCategories[0].name, petsCategoryName)
        XCTAssertEqual(receivedCategories[0].id, category.id)
    }
    
    func testPetCategoryPivotCanBeRemoved() throws {
        let user = try User.create(name: petsUserName, username: petsUserUsername, on: conn)
        let pet = try Pet.create(name: petsName, age: petsAge, userID: user.requireID(), on: conn)
        let category = try Category.create(name: petsCategoryName, on: conn)
        let _ = try pet.categories.attach(category, on: conn).wait()
        let body: EmptyBody? = nil
        let _ = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())/categories/\(category.requireID())", method: .DELETE, body: body, isLoggedInRequest: true)
        
        let response = try app.sendRequest(to: "\(petsURI)/\(pet.requireID())/categories", method: .GET, body: body, isLoggedInRequest: true)
        let receivedCategories = try response.content.decode([Category].self).wait()
        
        XCTAssertEqual(receivedCategories.count, 0)
    }
    
    static let allTests = [
        ("testPetCanBeSaved", testPetCanBeSaved),
        ("testSinglePetCanBeRetrieved", testSinglePetCanBeRetrieved),
        ("testAllPetsCanBeRetrieved", testAllPetsCanBeRetrieved),
        ("testPetCanBeUpdated", testPetCanBeUpdated),
        ("testPetCanBeDeleted", testPetCanBeDeleted),
        ("testUserCanBeRetrieved", testUserCanBeRetrieved),
        ("testPetCategoryPivotCanBeSaved", testPetCategoryPivotCanBeSaved),
        ("testCategoriesCanBeRetrieved", testCategoriesCanBeRetrieved),
        ("testPetCategoryPivotCanBeRemoved", testPetCategoryPivotCanBeRemoved)
    ]
}
