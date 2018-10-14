import FluentSQLite

final class PetCategoryPivot: SQLitePivot, ModifiablePivot {
    var id: Int?
    var petID: Pet.ID
    var categoryID: Category.ID
    
    typealias Left = Pet
    typealias Right = Category
    
    static var leftIDKey: LeftIDKey {
        return \.petID
    }
    
    static var rightIDKey: RightIDKey {
        return \.categoryID
    }
    
    init(_ pet: Pet, _ category: Category) throws {
        self.petID = try pet.requireID()
        self.categoryID = try category.requireID()
    }
}

extension PetCategoryPivot: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: conn) { (builder) in
            try addProperties(to: builder)
            builder.reference(from: \.petID, to: \Pet.id, onDelete: .cascade)
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
        }
    }
}
