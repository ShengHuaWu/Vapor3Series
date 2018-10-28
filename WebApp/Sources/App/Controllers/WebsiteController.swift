import Vapor
import Leaf

final class WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("vapor")
        
        websiteRoute.get(use: indexHandler)
        websiteRoute.get("users", use: allUsersHandler)
        websiteRoute.get("users", User.parameter, use: userHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        let content = IndexContent(title: "Models")
        return try req.view().render("index", content)
    }
    
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).decode(data: User.Public.self).all().flatMap(to: View.self) { users in
            let publicUsers = users.isEmpty ? nil : users
            let content = AllUsersContent(title: "All Users", users: publicUsers)
            return try req.view().render("allUsers", content)
        }
    }
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            return try user.pets.query(on: req).all().flatMap(to: View.self) { pets in
                let publicUser = user.toPublic()
                let content = UserContext(title: publicUser.name, user: publicUser, pets: pets)
                return try req.view().render("user", content)
            }
        }
    }
}

struct IndexContent: Encodable {
    let title: String
}

struct AllUsersContent: Encodable {
    let title: String
    let users: [User.Public]?
}

struct UserContext: Encodable {
    let title: String
    let user: User.Public
    let pets: [Pet]
}
