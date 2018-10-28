import FluentSQLite
import Vapor
import Authentication
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(AuthenticationProvider())
    try services.register(LeafProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(FileMiddleware.self)
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .sqlite)
    migrations.add(migration: AdminUser.self, database: .sqlite)
    migrations.add(model: Token.self, database: .sqlite)
    migrations.add(model: Pet.self, database: .sqlite)
    migrations.add(model: Category.self, database: .sqlite)
    migrations.add(model: PetCategoryPivot.self, database: .sqlite)
    services.register(migrations)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}
