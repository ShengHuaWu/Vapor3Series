import Vapor

final class PetsController: RouteCollection {
    func boot(router: Router) throws {
        let petsRoute = router.grouped("api", "pets")

        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenProtected = petsRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenProtected.get(use: getAllHandler)
        tokenProtected.get(Pet.parameter, use: getOneHandler)
        tokenProtected.post(use: createHandler)
        tokenProtected.put(Pet.parameter, use: updateHandler)
        tokenProtected.delete(Pet.parameter, use: deleteHandler)
        tokenProtected.get(Pet.parameter, "user", use: getUserHandler)
        tokenProtected.post(Pet.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        tokenProtected.get(Pet.parameter, "categories", use: getCategoriesHandler)
        tokenProtected.delete(Pet.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
    }

    func getAllHandler(_ req: Request) throws -> Future<[Pet]> {
        return Pet.query(on: req).decode(data: Pet.self).all()
    }

    func getOneHandler(_ req: Request) throws -> Future<Pet> {
        return try req.parameters.next(Pet.self)
    }

    func createHandler(_ req: Request) throws -> Future<Pet> {
        return try req.content.decode(Pet.self).save(on: req)
    }

    func updateHandler(_ req: Request) throws -> Future<Pet> {
        return try flatMap(to: Pet.self, req.parameters.next(Pet.self), req.content.decode(Pet.self)) { (pet, updatedPet) in
            pet.name = updatedPet.name
            pet.age = updatedPet.age
            pet.userID = updatedPet.userID
            return pet.save(on: req)
        }
    }

    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Pet.self).flatMap { (pet) in
            return pet.delete(on: req).transform(to: HTTPStatus.noContent)
        }
    }

    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Pet.self).flatMap(to: User.Public.self) { (pet) in
            return pet.user.get(on: req).toPublic()
        }
    }

    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Pet.self), req.parameters.next(Category.self)) { (pet, category) in
            return pet.categories.attach(category, on: req).transform(to: .created)
        }
    }

    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Pet.self).flatMap(to: [Category].self) { (pet) in
            return try pet.categories.query(on: req).all()
        }
    }

    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Pet.self), req.parameters.next(Category.self)) { (pet, category) in
            return pet.categories.detach(category, on: req).transform(to: .noContent)
        }
    }
}
