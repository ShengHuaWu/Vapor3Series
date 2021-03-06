## Vapor 3 Series IV - Relationship
In [our previous article](https://medium.com/swift2go/vapor-3-series-iii-testing-b192be079c9e), we enabled testing and wrote unit tests for each endpoint.
Besides, we managed to run these tests on Linux environment with Docker as well.
Testing allows us to develop and evolve our application quickly, because the test suite lets us verify everything still works as we change our codebase.
In this article, we are going to explore two different kind of relationships among our models --- parent-child and sibling relationships.
A parent-child relationship describes an ownership of one or more models, and it is known as one-to-one and one-to-many relationships.
On the other hand, a sibling relationship describes links between two models, and it is known as many-to-many relationship.

Please notice that this article will base on [the previous implementation](../Testing).

### Preparation
Before diving into relationships, we have to create two new model types as well as their controllers.
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
These lines are just some boilerplate code to create our `Pet` model, and it has a `name` property of type `String` and an `age` property of type `Int`.
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
Again, we just create our `Category` model here, and it has one `name` property of type `String`.

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
As we mentioned before, a parent-child relationship is an ownership between two models, and we are going to build this ownership relationship between our `User` and `Pet` models.
More specifically, one user can have one or more pets, but a pet can only have one owner (user).
First of all, open `Pet.swift` and add a new property after `var age: Int`.
```
var userID: User.ID
```
This line adds a property of type `User.ID`, and this property is not optional so a pet must have a user.
Furthermore, please replace the initializer with the following lines to reflect the new property.
```
init(name: String, age: Int, userID: User.ID) {
    self.name = name
    self.age = age
    self.userID = userID
}
```
Next, open `PetsController.swift` and rewrite `updateHandler` method with the following code for the new property.
```
func updateHandler(_ req: Request) throws -> Future<Pet> {
    return try flatMap(to: Pet.self, req.parameters.next(Pet.self), req.content.decode(Pet.self)) { (pet, updatedPet) in
        pet.name = updatedPet.name
        pet.age = updatedPet.age
        pet.userID = updatedPet.userID
        return pet.save(on: req)
    }
}
```

Now, our `User` and `Pet` models are linked with parent-child relationship, but it will be even more useful if we are able to query the relationships from each side.
Open `Pet.swift` and add an extension at the bottom of the file to get pet's user.
```
extension Pet {
    var user: Parent<Pet, User> {
        return parent(\.userID)
    }
}
```
This computed property returns `Fluent`'s generic `Parent` type, and it uses `parent(_:)` function to retrieve the parent which is pet's user.
Then swift to `PetsController.swift` and add a new route handler under `deleteHandler`.
```
func getUserHandler(_ req: Request) throws -> Future<User.Public> {
    return try req.parameters.next(Pet.self).flatMap(to: User.Public.self) { (pet) in
        return pet.user.get(on: req).toPublic()
    }
}
```
This handler uses the computed property just created by us to get pet's user and returns `Future<User.Public>`.
Moreover, we have to register the new route handler at the end of `boot(router:)` method.
```
tokenProtected.get(Pet.parameter, "user", use: getUserHandler)
```
As a result, it connects an HTTP GET request to `api/pets/:pet_id/user` to the new route handler.
On the other hand, open `User.swift` and append a new computed property after `toPublic()` method.
```
var pets: Children<User, Pet> {
    return children(\.userID)
}
```
This computed property returns `Fluent`'s generic `Children` type, and it uses `children(_:)` function to retrieve user's pets.
Again, switch to `UsersController.swift` and write a new route handler after `loginHandler` method.
```
func getPetsHandler(_ req: Request) throws -> Future<[Pet]> {
    return try req.parameters.next(User.self).flatMap(to: [Pet].self) { (user) in
        return try user.pets.query(on: req).all()
    }
}
```
This handler uses the new computed property to get user's pets and returns `Future<[Pet]>`.
Similarly, we need to register the new route handler at the end of `boot(router:)` method.
```
tokenProtected.get(User.parameter, "pets", use: getPetsHandler)
```
Therefore, it connects a HTTP GET request to `api/users/:user_id/pets` to the new route handler, and we can test these two new endpoints with Postman.

Although we just finish establishing the parent-child relationship between our `User` and `Pet` models with `Fluent`, there is still no link between `User` table and `Pet` table in the database.
We should set up foreign key constraints to ensure that a pet cannot be created with a non-existing user and a user cannot be deleted until all his/her pets have been deleted.
Since foreign key constraints can be set up within the migration, open `Pet.swift` and replace `extension Pet: Migration {}` with the following lines.
```
extension Pet: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: conn) { (builder) in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}
```
Here, we add all fields to the database with `addProperties(to:)` function, and add a reference between `userID` property on our `Pet` model and `id` property on our `User` model, which sets up the foreign key constraint between two tables.
Since we are linking `userID` property of our `Pet` model to `User` table, we must create `User` table first.
Go back to `configure.swift` and double check that `User` migration is above `Pet` migration as the following.
```
migrations.add(model: User.self, database: .sqlite)
// ...
migrations.add(model: Pet.self, database: .sqlite)
```
This will make sure that `Fluent` creates the tables in the correct order.

### Sibling Relationship
Unlike a parent-child relationship, a sibling relationship doesn't have limits between two models, for example, if there is a sibling relationship between our `Pet` and `Category` models, a pet can belong one or more categories and a category can contain one or more pets.
However, we cannot just add a reference to our `Category` directly in our `Pet` model, because it's too inefficient to query.
Instead, we need a separate model to hold on to the sibling relationship and it's called a pivot.
Let's create our new pivot model with Terminal and regenerate our Xcode project file.
```
touch Sources/App/Models/PetCategoryPivot.swift
vapor xcode -y
```
Then, open `PetCategoryPivot.swift` and add the following code.
```
import FluentSQLite

final class PetCategoryPivot: SQLitePivot, ModifiablePivot {
    var id: Int?
    var petID: Pet.ID
    var categoryID: Category.ID

    typealias Left = Pet
    typealias Right = Category

    static var leftIDKey: LeftIDKey {
        return \.petID
    }

    static var rightIDKey: RightIDKey {
        return \.categoryID
    }

    init(_ pet: Pet, _ category: Category) throws {
        self.petID = try pet.requireID()
        self.categoryID = try category.requireID()
    }
}

extension PetCategoryPivot: Migration {}
```
Here we take the advantage of `ModifiablePivot` protocol to obtain some syntactic sugar for adding and removing the relationships.
Besides, we add two properties to link the identifiers of our `Pet` and `Category` models respectively, and  also define `Left` and `Right` types to tell `Fluent` what the two types in the relationship are.
After creating our new pivot model, open `configure.swift` and append our new pivot model to the migration list after `migrations.add(model: Category.self, database: .sqlite)`.
```
migrations.add(model: PetCategoryPivot.self, database: .sqlite)
```  

In order to actually create a relationship between our `Pet` and `Category` models, we have to use the new pivot.
Let's switch to `Pet.swift` and append a new computed property under `var user: Parent<Pet, User>`.
```
var categories: Siblings<Pet, Category, PetCategoryPivot> {
    return siblings()
}
```
This property returns the sibling of a `Pet` that are of type `Category`, and it uses `Fluent`'s `siblings()` function to retrieve all the categories.
After appending the computed property, open `PetsController.swift` and add the following new route handler after `getUserHandler` method.
```
func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try flatMap(to: HTTPStatus.self, req.parameters.next(Pet.self), req.parameters.next(Category.self)) { (pet, category) in
        return pet.categories.attach(category, on: req).transform(to: .created)
    }
}
```
This route handler uses `attach(_:on:)` function to create the sibling relationship between our `Pet` and `Category` models.
However, we have to register this route handler at the end of `boot(router:)` method before trying it.
```
tokenProtected.post(Pet.parameter, "categories", Category.parameter, use: addCategoriesHandler)
```
This line connects a HTTP POST request to `api/pets/:pet_id/categories/:category_id` to the new route handler.

At this point, our `Pet` and `Category` models are linked with a sibling relationship, but it will be more useful if we can view these relationships.
Within `PetsController.swift`, add another new route handler under `addCategoriesHandler`.
```
func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
    return try req.parameters.next(Pet.self).flatMap(to: [Category].self) { (pet) in
        return try pet.categories.query(on: req).all()
    }
}
```
This route handler uses `query(on:)` function to get the categories, and then we need to register this route handler at the bottom of `boot(router:)` method as well.
```
tokenProtected.get(Pet.parameter, "categories", use: getCategoriesHandler)
```
This line connects a HTTP GET request to `api/pets/:pet_id/categories` to the new route handler.
On the other hand, open `Category.swift` and add an extension at the end of the file.
```
extension Category {
    var pets: Siblings<Category, Pet, PetCategoryPivot> {
        return siblings()
    }
}
```
This extension contains one computed property, and this property returns the sibling of a `Category` that are of type `Pet`.
Furthermore, it also uses `Fluent`'s `siblings()` function to retrieve all the pets.
After creating the extension, switch to `CategoriesController.swift` and append a new route handler at the end of the file.
```
func getPetsHandler(_ req: Request) throws -> Future<[Pet]> {
    return try req.parameters.next(Category.self).flatMap(to: [Pet].self) { (category) in
        return try category.pets.query(on: req).all()
    }
}
```
This route handler uses `query(on:)` function to get the pets, and then we also have to register this route handler at the bottom of `boot(router:)` method.
```
tokenProtected.get(Category.parameter, "pets", use: getPetsHandler)
```
This line connects a HTTP GET request to `api/categories/:category_id/pets` to the new route handler.

Last but not least, we should take care of removing the sibling relationship, and fortunately removing a sibling relationship is very similar to adding the relationship.
Switch back to `PetsController.swift` and add one more route handler after `getCategoriesHandler`.
```
func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try flatMap(to: HTTPStatus.self, req.parameters.next(Pet.self), req.parameters.next(Category.self)) { (pet, category) in
        return pet.categories.detach(category, on: req).transform(to: .noContent)
    }
}
```
This route handler uses `detach(_:on:)` to remove the relationship, and returns a `204 No Content` HTTP status.
Again, we have to register the route handler at the end of `boot(router:)` method.
```
tokenProtected.delete(Pet.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
```
This line connects a HTTP DELETE request to `api/pets/:pet_id/categories/:category_id` to the new route handler, and we can test these four new endpoints with Postman.

As creating parent-child relationships previously, it's also a good practice to use foreign key constraints with sibling relationships.
Currently, `PetCategoryPivot` does not check the identifiers for the pets and categories, so we are able to delete pets and categories that are still linked by the pivot.
Let's fix this by opening `PetCategoryPivot.swift` and replacing `extension PetCategoryPivot: Migration {}` with the following lines.
```
extension PetCategoryPivot: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: conn) { (builder) in
            try addProperties(to: builder)
            builder.reference(from: \.petID, to: \Pet.id, onDelete: .cascade)
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
        }
    }
}
```
Inside this extension, we add all fields to the database with `addProperties(to:)` function, and add a reference between `petID` property on `PetCategoryPivot` and `id` property on `Pet`, just the same with what we did for parent-child relationships.
The only new thing here is `.cascade`, which means the relationship will be automatically removed when we delete the pet from the database.
Besides, we do the same thing to `categoryID` property on `PetCategoryPivot` and `id` property on `Category`.

### Conclusion
[Here](https://github.com/ShengHuaWu/Vapor3Series/tree/master/Relationship) is the entire project.

Let's recap our journey of relationships.
First of all, we create two new `Pet` and `Category` models and their controllers.
Then, we link our `User` and `Pet` with parent-child relationships by adding a reference into our `Pet` model directly, and use foreign key constraints to link `User` table and `Pet` table in the database.
After implementing parent-child relationships, we create a new `PetCategoryPivot` model and use it to link our `Pet` and `Category` models with sibling relationships.
Similarly, we also take the advantage of foreign key constraints to link `Pet` table and `Category` table in the database.
However, there are still something missing here.
Please recall [our previous article](https://medium.com/swift2go/vapor-3-series-iii-testing-b192be079c9e) and it's always a good practice to write unit tests for the new relationships.
The unit tests are left as exercises since they are not highly related to this topic, but I have included them with [the project](https://github.com/ShengHuaWu/Vapor3Series/tree/master/Relationship) as well.
