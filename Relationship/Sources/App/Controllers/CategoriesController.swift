import Vapor

final class CategoriesControll: RouteCollection {
    func boot(router: Router) throws {
        let categoriessRoute = router.grouped("api", "categories")
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenProtected = categoriessRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenProtected.get(use: getAllHandler)
        tokenProtected.get(Category.parameter, use: getOneHandler)
        tokenProtected.post(use: createHandler)
        tokenProtected.put(Category.parameter, use: updateHandler)
        tokenProtected.delete(Category.parameter, use: deleteHandler)
        tokenProtected.get(Category.parameter, "pets", use: getPetsHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).decode(Category.self).all()
    }
    
    func getOneHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
    }
    
    func createHandler(_ req: Request) throws -> Future<Category> {
        return try req.content.decode(Category.self).save(on: req)
    }
    
    func updateHandler(_ req: Request) throws -> Future<Category> {
        return try flatMap(to: Category.self, req.parameters.next(Category.self), req.content.decode(Category.self)) { (category, updatedCategory) in
            category.name = updatedCategory.name
            return category.save(on: req)
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Category.self).flatMap { (category) in
            return category.delete(on: req).transform(to: HTTPStatus.noContent)
        }
    }
    
    func getPetsHandler(_ req: Request) throws -> Future<[Pet]> {
        return try req.parameters.next(Category.self).flatMap(to: [Pet].self) { (category) in
            return try category.pets.query(on: req).all()
        }
    }
}
