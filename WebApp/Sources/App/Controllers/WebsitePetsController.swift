import Vapor
import Leaf

final class WebsitePetsController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("pets")
        
        websiteRoute.get(use: allPetsHandler)
        websiteRoute.get(Pet.parameter, use: petHandler)
        websiteRoute.get("create", use: createPetHandler)
        websiteRoute.post("create", use: createPetPOSTHandler)
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
    
    func createPetHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).decode(data: User.Public.self).all().flatMap(to: View.self) { users in
            let content = CreatePetContent(users: users)
            return try req.view().render("createPet", content)
        }
    }
    
    func createPetPOSTHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(Pet.self).flatMap(to: Response.self) { pet in
            return pet.save(on: req).map(to: Response.self) { pet in
                guard let id = pet.id else {
                    throw Abort(.internalServerError)
                }
                
                return req.redirect(to: "/vapor/pets/\(id)")
            }
        }
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
}

struct CreatePetContent: Encodable {
    let title = "Create a Pet"
    let users: [User.Public]
}
