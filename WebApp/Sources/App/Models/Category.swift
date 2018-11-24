import Vapor
import FluentSQLite

final class Category: Codable {
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Category: SQLiteModel {}
extension Category: Content {}
extension Category: Parameter {}
extension Category: Migration {}

extension Category {
    var pets: Siblings<Category, Pet, PetCategoryPivot> {
        return siblings()
    }
    
    static func addCategory(_ name: String, to pet: Pet, on req: Request) throws -> Future<Void> {
        return Category.query(on: req).filter(\.name == name).first().flatMap(to: Void.self) { foundCategory in
            if let category = foundCategory {
                return pet.categories.attach(category, on: req).transform(to: ())
            } else {
                let category = Category(name: name)
                return category.save(on: req).flatMap(to: Void.self) { savedCategory in
                    return pet.categories.attach(savedCategory, on: req).transform(to: ())
                }
            }
        }
    }
    
    static func addCategories(_ names: [String], to pet: Pet, on req: Request) throws -> [Future<Void>] {
        guard !names.isEmpty else { return [] }
        
        return try names.map { try addCategory($0, to: pet, on: req) }
    }
}
