## Vapor 3 Series II - Authentication
In [our previous article](https://medium.com/swift2go/vapor-3-series-i-crud-with-controllers-d7848f9c193b), we finished a simple RESTful API server with Vapor 3.
More specifically, we implemented our `User` model to store data into a SQLite database and our `UsersController` to handle interactions from a client.
Although our server has many great features already, it also has one problem: anyone can create new users and delete them.
In other words, there is no authentication on the endpoints to ensure that only known users can manipulate the database.
In this article, I am going to demonstrate how to store passwords and authenticated users, and how to protect our endpoints with HTTP basic and token authentications.

Please notice that this article will base on [the previous implementation](../CRUDControllers).

### User Password
Generally speaking, authentication is the process of verifying who someone is, and one common way to authenticate users is using username and password. Open our `User.swift` file and add the following property below `var username: String`.
```
var password: String
```
Next, we should replace the initializer to store the new property with the following.
```
init(name: String, username: String, password: String) {
    self.name = name
    self.username = username
    self.password = password
}
```
Since our `User` model already conforms `Content` protocol, we don't have to make any additional changes to create users with passwords.

However, instead of storing passwords in plain text, we should always store passwords in a secure way.
Fortunately, Vapor provides `BCrypt` to hash passwords, and we can take the advantage of this to secure passwords.
Switch to `UsersController.swift` file, and append the following line below `import Vapor`.
```
import Crypto
```
This import statement allows us to use `BCrypt`, and we can use it within `createHandler` and `updateHandler` methods.
Let's replace these two methods with the following lines.
```
func createHandler(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap { (user) in
            user.password = try BCrypt.hash(user.password)
            return user.save(on: req)
        }
    }

func updateHandler(_ req: Request) throws -> Future<User> {
    return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(User.self)) { (user, updatedUser) in
        user.name = updatedUser.name
        user.username = updatedUser.username
        user.password = try BCrypt.hash(updatedUser.password)
        return user.save(on: req)
    }
}
```
The new methods will hash the user's password before saving it into the database.

At this point, if we try to create one user and retrieve afterward with Postman, we can see that the response returns the password hash.
However, we should protect password hashes and never return them in responses.
In order to achieve this, go back to `User` model and write the following lines below `User`'s new initializer.
```
final class Public: Codable {
    var id: Int?
    var name: String
    var username: String

    init(id: Int?, name: String, username: String) {
        self.id = id
        self.name = name
        self.username = username
    }
}
```
This creates an inner class to represent a public view of `User`.
Next, add the following line below `extension User: Content {}`.
```
extension User.Public: Content {}
```
This line allows us to return this public view in responses.
Moreover, let's write some helper methods for `User` and `Future` to keep our `UsersController` concise.
Please append the following extensions at the bottom of our `User` model.
```
extension User {
    func toPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension Future where T: User {
    func toPublic() -> Future<User.Public> {
        return map(to: User.Public.self) { (user) in
            return user.toPublic()
        }
    }
}
```
These two new methods help us to change our router handlers to return the public view.
Finally, within our `UsersController`, change our handler methods to return the public view.
```
final class UsersController: RouteCollection {
    // ...

    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }

    func getOneHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).toPublic()
    }

    func createHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.content.decode(User.self).flatMap { (user) in
            user.password = try BCrypt.hash(user.password)
            return user.save(on: req).toPublic()
        }
    }

    func updateHandler(_ req: Request) throws -> Future<User.Public> {
        return try flatMap(to: User.Public.self, req.parameters.next(User.self), req.content.decode(User.self)) { (user, updatedUser) in
            user.name = updatedUser.name
            user.username = updatedUser.username
            user.password = try BCrypt.hash(updatedUser.password)
            return user.save(on: req).toPublic()
        }
    }

    // ...
}
```
Now, any calls to our endpoints to retrieve a user won't return a password hash.

### Basic Authentication
Vapor already has a package to help with handling many types of authentication, including [HTTP basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication).
Open `Package.swift` and replace `.package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0")` with the following lines.
```
.package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
.package(url: "https://github.com/vapor/auth.git", from: "2.0.0-rc")
```
This adds the authentication package as a dependency to our project.
Furthermore, change the dependencies array for the `App` target to the following.
```
.target(name: "App", dependencies: ["FluentSQLite", "Vapor", "Authentication"])
```
This adds the `Authentication` module as a dependency to the `App` target.
Then, please regenerate the Xcode project to install the new dependency with `vapor xcode -y`.
Before modifying our `User` model, we have to change `configure.swift` file to adopt the new dependency.
Go to `configure.swift` file and append the following line below `import Vapor`.
```
import Authentication
```
Additionally, add the following line under `try services.register(FluentSQLiteProvider())` as well.
```
try services.register(AuthenticationProvider())
```
This line registers the necessary services with our application to ensure authentication works.

Let's start to use the new dependency in our `User` model.
First of all, append the following line below `import FluentSQLite`.
```
import Authentication
```
After that, we are able to adopt HTTP basic authentication with the `Authentication` module.
Secondly, please add the following lines at the bottom of our `User` model.
```
extension User: BasicAuthenticatable {
    static var usernameKey: UsernameKey {
        return \User.username
    }

    static var passwordKey: PasswordKey {
        return \User.password
    }
}
```
This extension tells Vapor which property of our `User` model is the username and which one is the password.
Since HTTP basic authentication uses the username and password to identify users, we should prevent multiple users from having the same username.
Let's replace `extension User: Migration {}` with the following lines.
```
extension User: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: conn) { (builder) in
            try addProperties(to: builder)
            builder.unique(on: \.username)
        }
    }
}
```
This custom migration will add all the columns to the `User` table using `User`'s properties, and add a unique index to `username` on `User`.

Next, switch to our `UsersController` and add the following lines at the bottom of `boot(router:)` method.
```
let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
let guardAuthMiddleware = User.guardAuthMiddleware()
let basicProtected = usersRoute.grouped(basicAuthMiddleware, guardAuthMiddleware)
basicProtected.post(use: createHandler)
```
Here we use two middlewares to ensure that requests of creating a user contain a valid authorization, otherwise an error will be thrown.
Moreover, inside `boot(router:)` method, please remove the following line as well.
```
usersRoute.post(use: createHandler)
```

At this point, if we run the application and try to create a new user with Postman, we are going to receive a `401 Unauthorized` error response.
Since we are using an in-memory database, there is no existing user in the database every time we run the application.
As a result, the authentication causes it's impossible for us to create a new user.
However, one way to solve this is to seed the database and create a user when the application boots up, and Vapor's `Migration` protocol give us a perfect place to achieve it.
Let's go back to our `User` model and append the following lines at the bottom of the file.
```
struct AdminUser: Migration {
    typealias Database = SQLiteDatabase

    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        let password = try? BCrypt.hash("password") // NOT do this for production
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }

        let user = User(name: "Admin", username: "admin", password: hashedPassword)
        return user.save(on: conn).transform(to: ())
    }

    static func revert(on conn: SQLiteConnection) -> Future<Void> {
        return .done(on: conn)
    }
}
```
Obviously, for production neither should we use `password` as the password for our admin user, nor hardcode the password.
One possible solution is to read the password from an environment variable.
Last but not least, inside `configure.swift` please append the following line under `migrations.add(model: User.self, database: .sqlite)`.
```
migrations.add(migration: AdminUser.self, database: .sqlite)
```
This line adds our `AdminUser` to the list of migrations so our application executes the migration at the next launch.
Now, we are able to satisfy HTTP basic authentication with the username and password of our `AdminUser` on Postman.

### Token Authentication
At this stage, only authenticated users can create users, but all other endpoints are still unprotected.
Besides, asking a user to give credentials with each request is impractical, and we don't want to store a user's password anywhere in our application.
Instead, we should provide an endpoint for users to log in, and we can replace their credentials with a token after they log in.

Let's start to write our `Token` class.
Open Terminal to create a new file and regenerate Xcode project as the followings.
```
touch Sources/App/Models/Token.swift
vapor xcode -y
```
Next, please write the following code into our new `Token.swift` file.
```
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
```
Basically, we define our `Token` model that contains the token string and the token owner's ID, and a helper method to generate a token for a login user.
Then, Switch to `configure.swift` and add the following line before `services.register(migrations)`.
```
migrations.add(model: Token.self, database: .sqlite)
```
This line adds our `Token` model to the list of migrations so our application executes the migration at the next launch.
Open our `UsersController` to write the new login method below `deleteHandler` method.
```
func loginHandler(_ req: Request) throws -> Future<Token> {
    let user = try req.requireAuthenticated(User.self)
    let token = try Token.generate(for: user)
    return token.save(on: req)
}
```
Since we are going to protect this method with HTTP basic authentication, we can get the authenticated user from the request, and then create a token for the user.
After this, inside `boot(router:)` method, please add the following line under `basicProtected.post(use: createHandler)`.
```
basicProtected.post("login", use: loginHandler)
```
Now, we can run our application and try to create a token for our admin user with Postman.
