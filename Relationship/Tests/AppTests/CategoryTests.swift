@testable import App
import Vapor
import FluentSQLite
import XCTest

final class CategoryTests: XCTestCase {
    typealias Category = App.Category
    
    let categoriesName = "Test Category"
    let categoriesURI = "/api/categories/"
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
    
    func testCategoryCanBeSaved() throws {
        let category = Category(name: categoriesName)
        let createCategoryResponse = try app.sendRequest(to: categoriesURI, method: .POST, body: category, isLoggedInRequest: true)
        let receivedCategory = try createCategoryResponse.content.decode(Category.self).wait()
        
        XCTAssertEqual(receivedCategory.name, categoriesName)
        XCTAssertNotNil(receivedCategory.id)
        
        let body: EmptyBody? = nil
        let getCategoriesResponse = try app.sendRequest(to: categoriesURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedCategories = try getCategoriesResponse.content.decode([Category].self).wait()
        
        XCTAssertEqual(receivedCategories.count, 1)
        XCTAssertEqual(receivedCategories[0].name, categoriesName)
        XCTAssertEqual(receivedCategories[0].id, receivedCategory.id)
    }
    
    func testSingleCategoryCanBeRetrieved() throws {
        let category = try Category.create(name: categoriesName, on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: "\(categoriesURI)/\(category.requireID())", method: .GET, body: body, isLoggedInRequest: true)
        let receivedCategory = try response.content.decode(Category.self).wait()
        
        XCTAssertEqual(receivedCategory.name, categoriesName)
        XCTAssertEqual(receivedCategory.id, category.id)
    }
    
    func testAllCategoriesCanBeRetrieved() throws {
        let category = try Category.create(name: categoriesName, on: conn)
        let body: EmptyBody? = nil
        let response = try app.sendRequest(to: categoriesURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedCategories = try response.content.decode([Category].self).wait()
        
        XCTAssertEqual(receivedCategories.count, 1)
        XCTAssertEqual(receivedCategories[0].name, categoriesName)
        XCTAssertEqual(receivedCategories[0].id, category.id)
    }
    
    func testCategoryCanBeUpdated() throws {
        let category = try Category.create(name: "Vapor 1234", on: conn)
        let updatedCategory = Category(name: categoriesName)
        let response = try app.sendRequest(to: "\(categoriesURI)/\(category.requireID())", method: .PUT, body: updatedCategory, isLoggedInRequest: true)
        let receivedCategory = try response.content.decode(Category.self).wait()
        
        XCTAssertEqual(receivedCategory.name, categoriesName)
        XCTAssertEqual(receivedCategory.id, category.id)
    }
    
    func testCategoryCanBeDeleted() throws {
        let category = try Category.create(name: categoriesName, on: conn)
        let body: EmptyBody? = nil
        let _ = try app.sendRequest(to: "\(categoriesURI)/\(category.requireID())", method: .DELETE, body: body, isLoggedInRequest: true)
        
        let response = try app.sendRequest(to: categoriesURI, method: .GET, body: body, isLoggedInRequest: true)
        let receivedCategories = try response.content.decode([Category].self).wait()
        
        XCTAssertEqual(receivedCategories.count, 0)
    }
    
    static let allTests = [
        ("testCategoryCanBeSaved", testCategoryCanBeSaved),
        ("testSingleCategoryCanBeRetrieved", testSingleCategoryCanBeRetrieved),
        ("testAllCategoriesCanBeRetrieved", testAllCategoriesCanBeRetrieved),
        ("testCategoryCanBeUpdated", testCategoryCanBeUpdated),
        ("testCategoryCanBeDeleted", testCategoryCanBeDeleted)
    ]
}
