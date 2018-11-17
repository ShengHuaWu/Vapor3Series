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

        let categoriesController = WebsiteCategoriesController()
        try websiteRoute.register(collection: categoriesController)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        let context = IndexContext(title: "Models")
        return try req.view().render("index", context)
    }
}

struct IndexContext: Encodable {
    let title: String
}
