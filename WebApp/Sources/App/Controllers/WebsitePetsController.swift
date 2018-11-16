import Vapor
import Leaf

final class WebsitePetsController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("pets")
        
        websiteRoute.get(use: allPetsHandler)
        websiteRoute.get(Pet.parameter, use: petHandler)
        websiteRoute.get("create", use: createPetHandler)
        websiteRoute.post("create", use: createPetPOSTHandler)
        websiteRoute.get(Pet.parameter, "edit", use: editPetHandler)
        websiteRoute.post(Pet.parameter, "edit", use: editPetPOSTHandler)
        websiteRoute.post(Pet.parameter, "delete", use: deletePetPOSTHandler)
    }
    
    func allPetsHandler(_ req: Request) throws -> Future<View> {
        return Pet.query(on: req).decode(Pet.self).all().flatMap(to: View.self) { pets in
            let content = AllPetsContent(title: "All Pets", pets: pets)
            return try req.view().render("allPets", content)
        }
    }
    
    func petHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Pet.self).flatMap(to: View.self) { pet in
            return try flatMap(to: View.self, pet.user.get(on: req), pet.categories.query(on: req).all()) { user, categories in
                let content = PetContent(title: pet.name, pet: pet, user: user.toPublic(), categories: categories)
                return try req.view().render("pet", content)
            }
        }
    }
    
    func createPetHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).decode(data: User.Public.self).all().flatMap(to: View.self) { users in
            let content = CreatePetContent(users: users)
            return try req.view().render("createPet", content)
        }
    }
    
    func createPetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(CreatePetData.self).flatMap(to: Response.self) { data in
            let pet = Pet(name: data.name, age: data.age, userID: data.userID)
            
            return pet.save(on: req).flatMap(to: Response.self) { pet in
                guard let id = pet.id else {
                    throw Abort(.internalServerError)
                }
                
                var categorySaves: [Future<Void>] = []
                for name in data.categoryNames ?? [] {
                    let save = try Category.addCategory(name, to: pet, on: req)
                    categorySaves.append(save)
                }
                
                let redirect = req.redirect(to: "/vapor/pets/\(id)")
                
                return categorySaves.flatten(on: req).transform(to: redirect)
            }
        }
    }
    
    func editPetHandler(_ req: Request) throws -> Future<View> {
        return try flatMap(to: View.self, req.parameters.next(Pet.self), User.query(on: req).decode(data: User.Public.self).all()) { pet, users in
            let content = EditPetContent(pet: pet, users: users)
            return try req.view().render("createPet", content)
        }
    }
    
    func editPetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(Pet.self), req.content.decode(Pet.self)) { pet, newPet in
            pet.name = newPet.name
            pet.age = newPet.age
            pet.userID = newPet.userID
            
            return pet.save(on: req).map(to: Response.self) { savedPet in
                guard let id = savedPet.id else {
                    throw Abort(.internalServerError)
                }
                
                return req.redirect(to: "/vapor/pets/\(id)")
            }
        }
    }
    
    func deletePetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Pet.self).delete(on: req).transform(to: req.redirect(to: "/vapor/pets"))
    }
}

struct AllPetsContent: Encodable {
    let title: String
    let pets: [Pet]
}

struct PetContent: Encodable {
    let title: String
    let pet: Pet
    let user: User.Public
    let categories: [Category]
}

struct CreatePetContent: Encodable {
    let title = "Create a Pet"
    let users: [User.Public]
}

struct EditPetContent: Encodable {
    let title = "Edit Pet"
    let pet: Pet
    let users: [User.Public]
    let editing = true
}

struct CreatePetData: Content {
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case name
        case age
        case categoryNames = "category_names"
    }
    
    let userID: User.ID
    let name: String
    let age: Int
    let categoryNames: [String]?
}
