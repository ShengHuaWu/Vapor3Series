## Vapor 3 Series III - Testing
In [our previous article](https://medium.com/swift2go/vapor-3-series-ii-authentication-ff17847a9659), we implemented two ways to authenticate users: HTTP basic authentication and bearer token authorization.
As a result, our application only accepts requests from authenticated users.
However, we should write some unit tests for our endpoints, even though our application is quite simple.
Testing is an important part of software development, and writing unit tests allows us to develop and evolve our application quickly.
In order to develop new feature quickly, we want to ensure that the existing features don't break, and having a thorough test suite lets us verify everything still works as we change our codebase.
In this article, I am going to demonstrate how to write unit tests for our CRUD endpoints and how to run the tests on Linux machine with Docker.

Please notice that this article will base on [the previous implementation](../Authentication).

### Preparation
One benefit to write our application in Swift is that we are able to run tests with the lovely Xcode.
However, in order to run tests with Xcode, we have to generate the test target beforehand.
Please open `Package.swift` and replace the line `.target(name: "Run", dependencies: ["App"])` with the following lines.
```
.target(name: "Run", dependencies: ["App"]),
.testTarget(name: "AppTests", dependencies: ["App"])
```
This tells Swift package manager, which is used by Vapor's toolbox, to generate `AppTests` target for our Xcode project.
Moreover, create `AppTests` folder and corresponding files with the following commands in Terminal as usual.
```
mkdir Tests/AppTests
touch Tests/AppTests/Application+Testable.swift
touch Tests/AppTests/User+Testable.swift
touch Tests/AppTests/UserTests.swift
```
In order to make our tests concise, we are going to write some helper methods for `Application` as well as our `User` model, so we create `Application+Testable.swift` and `User+Testable.swift` at first.
Besides, the unit tests for our endpoints will be located in `UserTests.swift`.
Then, regenerate our Xcode project file with `vapor xcode -y` command.
Finally, please open the project with Xcode.
The test target should appear and the project structure looks like the image below.
![test_target](../Resources/Testing/test_target.png)

Let's start with writing the helper methods for `Application`.
Please open `Application+Testable.swift` and add the following code.
```
@testable import App
import Vapor
import FluentSQLite
import Authentication

extension Application {
    static func testable() throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        try App.configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        try App.boot(app)

        return app
    }
}
```
Here, we import the necessary dependencies and create `testable` method which allows us to create a testable `Application` object.
Again, within the extension of `Application`, append the following lines.
```
extension Application {
    // ..

    func sendRequest<Body>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: Body?, isLoggedInRequest: Bool = false) throws -> Response where Body: Content {
        var headers = headers
        if isLoggedInRequest {
            let credentials = BasicAuthorization(username: "admin", password: "password")
            var tokenHeaders = HTTPHeaders()
            tokenHeaders.basicAuthorization = credentials
            let tokenBody: EmptyBody? = nil
            let tokenResponse = try sendRequest(to: "api/users/login", method: .POST, headers: tokenHeaders, body: tokenBody)
            let token = try tokenResponse.content.decode(Token.self).wait()
            headers.add(name: .authorization, value: "Bearer \(token.token)")
        }

        let httpRequest = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: httpRequest, using: self)
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        let responder = try make(Responder.self)

        return try responder.respond(to: wrappedRequest).wait()
    }
}

struct EmptyBody: Content {}
```
We create `sendRequest` method which sends a request to a path and returns a `Reponse`.
If the request requires authentication, we use the admin user to log in and obtain the token.
Furthermore, we define `EmptyBody` type to use when there's no body to send in a request, because we cannot use `nil` for a generic type directly.

### Test Endpoints

### Run Tests on Linux

### Conclusion
