import Vapor
import Leaf

final class WebsiteUsersController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoutes = router.grouped("users")
        
        websiteRoutes.get(use: allUsersHandler)
        websiteRoutes.get(User.parameter, use: userHandler)
        websiteRoutes.get(User.parameter, "edit", use: editUserHandler)
        websiteRoutes.post(User.parameter, "edit", use: editUserPOSTHandler)
        websiteRoutes.post(User.parameter, "delete", use: deleteUserPOSTHandler)
    }
    
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).decode(data: User.Public.self).all().flatMap(to: View.self) { users in
            let publicUsers = users.isEmpty ? nil : users
            let context = AllUsersContext(title: "All Users", users: publicUsers)
            return try req.view().render("allUsers", context)
        }
    }
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            return try user.pets.query(on: req).all().flatMap(to: View.self) { pets in
                let publicUser = user.toPublic()
                let context = UserContext(title: publicUser.name, user: publicUser, pets: pets)
                return try req.view().render("user", context)
            }
        }
    }
    
    func editUserHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            let publicUser = user.toPublic()
            let context = EditUserContext(user: publicUser)
            return try req.view().render("createUser", context)
        }
    }
    
    func editUserPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(User.self), req.content.decode(User.Public.self)) { user, newUser in
            user.name = newUser.name
            user.username = newUser.username
            
            return user.save(on: req).map(to: Response.self) { savedUser in
                guard let id = savedUser.id else {
                    throw Abort(.internalServerError)
                }
                
                return req.redirect(to: "/vapor/users/\(id)")
            }
        }
    }
    
    func deleteUserPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(User.self).delete(on: req).transform(to: req.redirect(to: "/vapor/users"))
    }
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User.Public]?
}

struct UserContext: Encodable {
    let title: String
    let user: User.Public
    let pets: [Pet]
}

struct EditUserContext: Encodable {
    let title = "Edit User"
    let user: User.Public
    let editing = true
}
