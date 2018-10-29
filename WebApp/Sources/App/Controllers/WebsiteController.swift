import Vapor
import Leaf

final class WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("vapor")
        
        websiteRoute.get(use: indexHandler)
        websiteRoute.get("users", use: allUsersHandler)
        websiteRoute.get("users", User.parameter, use: userHandler)
        websiteRoute.get("pets", use: allPetsHandler)
        websiteRoute.get("pets", Pet.parameter, use: petHandler)
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
                let content = UserContent(title: publicUser.name, user: publicUser, pets: pets)
                return try req.view().render("user", content)
            }
        }
    }
    
    func allPetsHandler(_ req: Request) throws -> Future<View> {
        return Pet.query(on: req).decode(Pet.self).all().flatMap(to: View.self) { pets in
            let content = AllPetsContent(title: "All Pets", pets: pets)
            return try req.view().render("allPets", content)
        }
    }
    
    func petHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Pet.self).flatMap(to: View.self) { pet in
            return pet.user.get(on: req).flatMap(to: View.self) { user in
                let content = PetContent(title: pet.name, pet: pet, user: user.toPublic())
                return try req.view().render("pet", content)
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

struct UserContent: Encodable {
    let title: String
    let user: User.Public
    let pets: [Pet]
}

struct AllPetsContent: Encodable {
    let title: String
    let pets: [Pet]
}

struct PetContent: Encodable {
    let title: String
    let pet: Pet
    let user: User.Public
}