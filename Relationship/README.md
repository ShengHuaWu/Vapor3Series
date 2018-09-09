## Vapor 3 Series IV - Relationship
In [our previous article](https://medium.com/swift2go/vapor-3-series-iii-testing-b192be079c9e), we enabled testing and wrote unit tests for each endpoint.
Besides, we managed to run these tests on Linux environment with Docker as well.
Testing allows us to develop and evolve our application quickly, because the test suite lets us verify everything still works as we change our codebase.
In this article, we are going to explore two different kind of relationships among our models --- parent-child and sibling relationships.
A parent-child relationship describes an ownership of one or more models, and it is known as one-to-one and one-to-many relationships.
On the other hand, a sibling relationship describes links between two models, and it is known as many-to-many relationship.

Please notice that this article will base on [the previous implementation](../Testing).

### Preparation
Before diving into relationships, we have to create two new model types and their controllers.
As usual, use Terminal to create the necessary files and regenerate our Xcode project file with the following lines.
```
touch Sources/App/Models/Pet.swift Sources/App/Models/Category.swift
touch Sources/App/Controllers/PetsController.swift Sources/App/Controllers/CategoriesController.swift
vapor xcode -y
```
After generating our Xcode project file, open `Pet.swift` and add the following code into the file.
```
import Vapor
import FluentSQLite

final class Pet: Codable {
    var id: Int?
    var name: String
    var age: Int

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

extension Pet: SQLiteModel {}
extension Pet: Parameter {}
extension Pet: Content {}
extension Pet: Migration {}
```
These lines are just some boilerplate code to create our `Pet` model, and it has a `name` property and an `age` property.
If you are still not familiar with these lines, please refer [our very first article --- CRUD with Controllers](https://medium.com/swift2go/vapor-3-series-i-crud-with-controllers-d7848f9c193b).

Next, open `PetsController.swift` and write the following lines.
```
import Vapor

final class PetsController: RouteCollection {
    func boot(router: Router) throws {
        let petsRoute = router.grouped("api", "pets")

        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenProtected = petsRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenProtected.get(use: getAllHandler)
        tokenProtected.get(Pet.parameter, use: getOneHandler)
        tokenProtected.post(use: createHandler)
        tokenProtected.put(Pet.parameter, use: updateHandler)
        tokenProtected.delete(Pet.parameter, use: deleteHandler)
    }

    func getAllHandler(_ req: Request) throws -> Future<[Pet]> { ... }

    func getOneHandler(_ req: Request) throws -> Future<Pet> { ... }

    func createHandler(_ req: Request) throws -> Future<Pet> { ... }

    func updateHandler(_ req: Request) throws -> Future<Pet> { ... }

    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { ... }
}
```
These lines create the endpoints of our `Pet` model, and these endpoints are protected by Bearer authentication, which we have already discussed in [the second article of this series](https://medium.com/swift2go/vapor-3-series-ii-authentication-ff17847a9659).
In addition, the implementation of each endpoint is left as an exercise.

Then, open `Category.swift` and add the following lines.
```
import Vapor
import FluentSQLite

final class Category: Codable {
    var id: Int?
    var name: String

    init(name: String) {
        self.name = name
    }
}

extension Category: SQLiteModel {}
extension Category: Content {}
extension Category: Parameter {}
extension Category: Migration {}
```
Again, we just create our `Category` model here, and it has one `name` property.

Next, open `CategoriesController.swift` and write the following lines.
```
import Vapor

final class CategoriesControll: RouteCollection {
    func boot(router: Router) throws {
        let categoriessRoute = router.grouped("api", "categories")

        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenProtected = categoriessRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenProtected.get(use: getAllHandler)
        tokenProtected.get(Category.parameter, use: getOneHandler)
        tokenProtected.post(use: createHandler)
        tokenProtected.put(Category.parameter, use: updateHandler)
        tokenProtected.delete(Category.parameter, use: deleteHandler)
    }

    func getAllHandler(_ req: Request) throws -> Future<[Category]> { ... }

    func getOneHandler(_ req: Request) throws -> Future<Category> { ... }

    func createHandler(_ req: Request) throws -> Future<Category> { ... }

    func updateHandler(_ req: Request) throws -> Future<Category> { ... }

    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> { ... }
}
```
Similarly, these lines create the endpoints of our `Category` model with Bearer authentication, and the implementation of each endpoint is an exercise as well.

After finishing our models and controllers, open `configure.swift` and append the following two lines under `migrations.add(model: Token.self, database: .sqlite)`.
```
migrations.add(model: Pet.self, database: .sqlite)
migrations.add(model: Category.self, database: .sqlite)
```
These two line add our `Pet` and `Category` models to the list of migrations, so our application executes the migration at the next launch.

Last but not least, open `router.swift` and append the following lines into `routes(_ router:)` function.
```
let petsController = PetsController()
try router.register(collection: petsController)

let categoriesController = CategoriesControll()
try router.register(collection: categoriesController)
```
At this point, we finish creating our models and controllers, so we are able to try these new endpoints with Postman.

### Parent-Child Relationship

### Sibling Relationship

### Conclusion
