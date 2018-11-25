import Vapor
import Leaf
import Authentication

final class WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoutes = router.grouped("vapor")
        let authSessionRoutes = websiteRoutes.grouped(User.authSessionsMiddleware())
        
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post("login", use: loginPOSTHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("register", use: registerHandler)
        authSessionRoutes.post("register", use: registerPOSTHandler)
        
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/vapor/login"))
        protectedRoutes.get(use: indexHandler)
        
        let usersController = WebsiteUsersController()
        try protectedRoutes.register(collection: usersController)
        
        let petsController = WebsitePetsController()
        try protectedRoutes.register(collection: petsController)
        
        let categoriesController = WebsiteCategoriesController()
        try protectedRoutes.register(collection: categoriesController)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        let userLoggedIn = try req.isAuthenticated(User.self)
        let showCookieMessage = req.http.cookies["cookies-accepted"] == nil
        let context = IndexContext(title: "Models", userLoggedIn: userLoggedIn, showCookieMessage: showCookieMessage)
        return try req.view().render("index", context)
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        
        return try req.view().render("login", context)
    }
    
    func loginPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(LoginData.self).flatMap(to: Response.self) { data in
            return User.authenticate(username: data.username, password: data.password, using: BCryptDigest(), on: req).map(to: Response.self) { authedUser in
                guard let user = authedUser else {
                    return req.redirect(to: "/vapor/login?error")
                }
                
                try req.authenticateSession(user)
                return req.redirect(to: "/vapor")
            }
        }
    }
    
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        return req.redirect(to: "/vapor/login")
    }
    
    func registerHandler(_ req: Request) throws -> Future<View> {
        let context = RegisterContext()
        return try req.view().render("register", context)
    }
    
    func registerPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(RegisterData.self).flatMap(to: Response.self) { data in
            let password = try BCrypt.hash(data.password)
            let user = User(name: data.name, username: data.username, password: password)
            return user.save(on: req).map(to: Response.self) { user in
                try req.authenticateSession(user)
                return req.redirect(to: "/vapor")
            }
        }
    }
}

struct IndexContext: Encodable {
    let title: String
    let userLoggedIn: Bool
    let showCookieMessage: Bool
}

struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool
    let userLoggedIn = false
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginData: Content {
    let username: String
    let password: String
}

struct RegisterContext: Encodable {
    let title = "Register"
    let userLoggedIn = false
}

struct RegisterData: Content {
    enum CodingKeys: String, CodingKey {
        case name
        case username
        case password
        case confirmPassword = "confirm_password"
    }
    
    let name: String
    let username: String
    let password: String
    let confirmPassword: String
}
