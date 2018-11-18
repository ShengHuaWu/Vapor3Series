import Vapor
import Leaf
import Authentication

final class WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoutes = router.grouped("vapor")
        let authSessionRoutes = websiteRoutes.grouped(User.authSessionsMiddleware())
        
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post("login", use: loginPOSTHandler)
        
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
        let context = IndexContext(title: "Models")
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
}

struct IndexContext: Encodable {
    let title: String
}

struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginData: Content {
    let username: String
    let password: String
}
