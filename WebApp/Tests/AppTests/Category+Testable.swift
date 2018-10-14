@testable import App
import FluentSQLite

extension App.Category {
    static func create(name: String, on conn: SQLiteConnection) throws -> App.Category {
        let category = Category(name: name)
        return try category.save(on: conn).wait()
    }
}
