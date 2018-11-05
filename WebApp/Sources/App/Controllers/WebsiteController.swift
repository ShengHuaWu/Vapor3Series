import Vapor
import Leaf

final class WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("vapor")
        
        websiteRoute.get(use: indexHandler)
        websiteRoute.get("users", use: allUsersHandler)
        websiteRoute.get("users", User.parameter, use: userHandler)
        websiteRoute.get("users", "create", use: createUserHandler)
        websiteRoute.post(User.self, at: "users", "create", use: createUserPOSTHandler)
        websiteRoute.get("pets", use: allPetsHandler)
        websiteRoute.get("pets", Pet.parameter, use: petHandler)
        websiteRoute.get("categories", use: allCategoriesHandler)
        websiteRoute.get("categories", Category.parameter, use: categoryHandler)
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
    
    func createUserPOSTHandler(_ req: Request, user: User) throws -> Future<Response> {
        return user.save(on: req).map(to: Response.self) { user in
            guard let id = user.id else {
                throw Abort(.internalServerError)
            }
            
            return req.redirect(to: "/vapor/users/\(id)")
        }
    }
    
    func createUserHandler(_ req: Request) throws -> Future<View> {
        let content = CreateUserContent()
        return try req.view().render("createUser", content)
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
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        return Category.query(on: req).decode(Category.self).all().flatMap(to: View.self) { categories in
            let content = AllCategoriesContent(title: "All Categories", categories: categories)
            return try req.view().render("allCategories", content)
        }
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self).flatMap(to: View.self) { category in
            return try category.pets.query(on: req).all().flatMap(to: View.self) { pets in
                let content = CategoryContent(title: category.name, category: category, pets: pets)
                return try req.view().render("category", content)
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

struct AllCategoriesContent: Encodable {
    let title: String
    let categories: [Category]
}

struct CategoryContent: Encodable {
    let title: String
    let category: Category
    let pets: [Pet]
}

struct CreateUserContent: Encodable {
    let title = "Create a User"
}
