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
}
