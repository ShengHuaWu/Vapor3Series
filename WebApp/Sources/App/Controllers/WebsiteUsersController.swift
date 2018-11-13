import Vapor
import Leaf
import Crypto

final class WebsiteUsersController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("users")
        
        websiteRoute.get(use: allUsersHandler)
        websiteRoute.get(User.parameter, use: userHandler)
        websiteRoute.get("create", use: createUserHandler)
        websiteRoute.post("create", use: createUserPOSTHandler)
        websiteRoute.get(User.parameter, "edit", use: editUserHandler)
        websiteRoute.post(User.parameter, "edit", use: editUserPOSTHandler)
        websiteRoute.post(User.parameter, "delete", use: deleteUserPOSTHandler)
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
                let content = UserContent(title: publicUser.name, user: publicUser, pets: pets)
                return try req.view().render("user", content)
            }
        }
    }
    
    func createUserHandler(_ req: Request) throws -> Future<View> {
        let content = CreateUserContent()
        return try req.view().render("createUser", content)
    }
    
    func createUserPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.self).flatMap(to: Response.self) { user in
            user.password = try BCrypt.hash(user.password)
            
            return user.save(on: req).map(to: Response.self) { user in
                guard let id = user.id else {
                    throw Abort(.internalServerError)
                }
                
                return req.redirect(to: "/vapor/users/\(id)")
            }
        }
    }
    
    func editUserHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            let publicUser = user.toPublic()
            let content = EditUserContent(user: publicUser)
            return try req.view().render("createUser", content)
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

struct AllUsersContent: Encodable {
    let title: String
    let users: [User.Public]?
}

struct UserContent: Encodable {
    let title: String
    let user: User.Public
    let pets: [Pet]
}

struct CreateUserContent: Encodable {
    let title = "Create a User"
    let creating = true
}

struct EditUserContent: Encodable {
    let title = "Edit User"
    let user: User.Public
    let editing = true
}
