## Vapor 3 Series II - Authentication
In [our previous article](https://medium.com/swift2go/vapor-3-series-i-crud-with-controllers-d7848f9c193b), we finished a simple RESTful API server with Vapor 3.
More specifically, we implemented our `User` model to store data into a SQLite database and our `UsersController` to handle interactions from a client.
Although our server has many great features now, it also has one problem: anyone can create new users and delete them.
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
This import statement allows us to use `BCrypt`, and we can use it in the `createHandler` and `updateHandler` methods.
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
Since HTTP basic authentication uses the username and password to identify users, we should prevent multiple users from having the same username.
Inside `User` model, please replace `extension User: Migration {}` with the following lines.
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
This custom migration will add all the columns to the `User` table using `User`'s properties, and add a unique index to `username` on User.

### Token Authentication
