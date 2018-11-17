import Vapor
import Leaf

final class WebsiteCategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let websiteRoute = router.grouped("categories")
        websiteRoute.get(use: allCategoriesHandler)
        websiteRoute.get(Category.parameter, use: categoryHandler)
    }
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        return Category.query(on: req).decode(Category.self).all().flatMap(to: View.self) { categories in
            let context = AllCategoriesContext(title: "All Categories", categories: categories)
            return try req.view().render("allCategories", context)
        }
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self).flatMap(to: View.self) { category in
            return try category.pets.query(on: req).all().flatMap(to: View.self) { pets in
                let context = CategoryContext(title: category.name, category: category, pets: pets)
                return try req.view().render("category", context)
            }
        }
    }
}

struct AllCategoriesContext: Encodable {
    let title: String
    let categories: [Category]
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let pets: [Pet]
}

