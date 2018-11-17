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
            let context = CreatePetContext(users: users)
            return try req.view().render("createPet", context)
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
            return try pet.categories.query(on: req).all().flatMap(to: View.self) { categories in
                let context = EditPetContext(pet: pet, users: users, categories: categories)
                return try req.view().render("createPet", context)
            }
        }
    }
    
    func editPetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(Pet.self), req.content.decode(CreatePetData.self)) { pet, data in
            pet.name = data.name
            pet.age = data.age
            pet.userID = data.userID
            
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
                    for newName in namesToAdd {
                        let save = try Category.addCategory(newName, to: savedPet, on: req)
                        categortResults.append(save)
                    }
                    
                    for nameToRemove in namesToRemove {
                        let categoryToRemove = existingCategories.first { $0.name == nameToRemove }
                        if let category = categoryToRemove {
                            let remove = savedPet.categories.detach(category, on: req)
                            categortResults.append(remove)
                        }
                    }
                    
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
    let users: [User.Public]
}

struct EditPetContext: Encodable {
    let title = "Edit Pet"
    let pet: Pet
    let users: [User.Public]
    let categories: [Category]
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
