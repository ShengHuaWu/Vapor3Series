import Vapor
import Leaf

final class WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("vapor")
        
        websiteRoute.get(use: indexHandler)
        
        let usersController = WebsiteUsersController()
        try websiteRoute.register(collection: usersController)
        
        let petsController = WebsitePetsController()
        try websiteRoute.register(collection: petsController)

        websiteRoute.get("categories", use: allCategoriesHandler)
        websiteRoute.get("categories", Category.parameter, use: categoryHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        let content = IndexContent(title: "Models")
        return try req.view().render("index", content)
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

struct AllCategoriesContent: Encodable {
    let title: String
    let categories: [Category]
}

struct CategoryContent: Encodable {
    let title: String
    let category: Category
    let pets: [Pet]
}
