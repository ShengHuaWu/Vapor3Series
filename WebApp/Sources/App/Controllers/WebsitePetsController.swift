import Vapor
import Leaf
import Crypto

final class WebsitePetsController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoutes = router.grouped("pets")
        
        websiteRoutes.get(use: allPetsHandler)
        websiteRoutes.get(Pet.parameter, use: petHandler)
        websiteRoutes.get("create", use: createPetHandler)
        websiteRoutes.post("create", use: createPetPOSTHandler)
        websiteRoutes.get(Pet.parameter, "edit", use: editPetHandler)
        websiteRoutes.post(Pet.parameter, "edit", use: editPetPOSTHandler)
        websiteRoutes.post(Pet.parameter, "delete", use: deletePetPOSTHandler)
    }
    
    func allPetsHandler(_ req: Request) throws -> Future<View> {
        return Pet.query(on: req).decode(Pet.self).all().flatMap(to: View.self) { pets in
            let context = AllPetsContext(title: "All Pets", pets: pets)
            return try req.view().render("allPets", context)
        }
    }
    
    func petHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Pet.self).flatMap(to: View.self) { pet in
            return try flatMap(to: View.self, pet.user.get(on: req), pet.categories.query(on: req).all()) { user, categories in
                let context = PetContext(title: pet.name, pet: pet, user: user.toPublic(), categories: categories)
                return try req.view().render("pet", context)
            }
        }
    }
    
    func createPetHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).decode(data: User.Public.self).all().flatMap(to: View.self) { users in
            let token = try CryptoRandom().generateData(count: 16).base64EncodedString()
            try req.session()["CSRF_TOKEN"] = token
            let context = CreatePetContext(csrfToken: token)
            return try req.view().render("createPet", context)
        }
    }
    
    func createPetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(CreatePetData.self).flatMap(to: Response.self) { data in
            let expectedToken = try req.session()["CSRF_TOKEN"]
            try req.session()["CSRF_TOKEN"] = nil
            guard expectedToken == data.csrfToken else {
                throw Abort(.badRequest)
            }
            
            let user = try req.requireAuthenticated(User.self)
            let pet = try Pet(name: data.name, age: data.age, userID: user.requireID())
            
            return pet.save(on: req).flatMap(to: Response.self) { pet in
                guard let id = pet.id else {
                    throw Abort(.internalServerError)
                }
                
                let redirect = req.redirect(to: "/vapor/pets/\(id)")
                return try Category.addCategories(data.categoryNames ?? [], to: pet, on: req).flatten(on: req).transform(to: redirect)
            }
        }
    }
    
    func editPetHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Pet.self).flatMap(to: View.self) { pet in
            return try pet.categories.query(on: req).all().flatMap(to: View.self) { categories in
                let context = EditPetContext(pet: pet, categories: categories)
                return try req.view().render("createPet", context)
            }
        }
    }
    
    func editPetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(Pet.self), req.content.decode(EditPetData.self)) { pet, data in
            pet.name = data.name
            pet.age = data.age
            
            let user = try req.requireAuthenticated(User.self)
            pet.userID = try user.requireID()
            
            return pet.save(on: req).flatMap(to: Response.self) { savedPet in
                guard let id = savedPet.id else {
                    throw Abort(.internalServerError)
                }
                
                return try savedPet.categories.query(on: req).all().flatMap(to: Response.self) { existingCategories in
                    let existingNames = existingCategories.map { $0.name }
                    let existingSet = Set<String>(existingNames)
                    let newSet = Set<String>(data.categoryNames ?? [])
                    
                    let namesToAdd = newSet.subtracting(existingSet)
                    let namesToRemove = existingSet.subtracting(newSet)
                    
                    var categortResults: [Future<Void>] = []
                    
                    let saves = try Category.addCategories(Array(namesToAdd), to: savedPet, on: req)
                    categortResults.append(contentsOf: saves)
                    
                    let removals = savedPet.removeCategories(Array(namesToRemove), from: existingCategories, on: req)
                    categortResults.append(contentsOf: removals)
                    
                    let redirect = req.redirect(to: "/vapor/pets/\(id)")
                    return categortResults.flatten(on: req).transform(to: redirect)
                }
            }
        }
    }
    
    func deletePetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Pet.self).delete(on: req).transform(to: req.redirect(to: "/vapor/pets"))
    }
}

struct AllPetsContext: Encodable {
    let title: String
    let pets: [Pet]
}

struct PetContext: Encodable {
    let title: String
    let pet: Pet
    let user: User.Public
    let categories: [Category]
}

struct CreatePetContext: Encodable {
    let title = "Create a Pet"
    let csrfToken: String
}

struct EditPetContext: Encodable {
    let title = "Edit Pet"
    let pet: Pet
    let categories: [Category]
    let editing = true
}

struct CreatePetData: Content {
    enum CodingKeys: String, CodingKey {
        case name
        case age
        case categoryNames = "category_names"
        case csrfToken = "csrf_token"
    }
    
    let name: String
    let age: Int
    let categoryNames: [String]?
    let csrfToken: String
}

struct EditPetData: Content {
    enum CodingKeys: String, CodingKey {
        case name
        case age
        case categoryNames = "category_names"
    }
    
    let name: String
    let age: Int
    let categoryNames: [String]?
}
