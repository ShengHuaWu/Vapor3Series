import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let usersGroup = router.grouped("api", "users")
    usersGroup.get(use: getAllHandler)
    usersGroup.get(User.parameter, use: getOneHandler)
    usersGroup.post(use: createHandler)
    usersGroup.put(User.parameter, use: updateHandler)
    usersGroup.delete(User.parameter, use: deleteHandler)
}

func getAllHandler(_ req: Request) throws -> Future<[User]> {
    return User.query(on: req).decode(User.self).all()
}

func getOneHandler(_ req: Request) throws -> Future<User> {
    return try req.parameters.next(User.self)
}

func createHandler(_ req: Request) throws -> Future<User> {
    return try req.content.decode(User.self).flatMap { (user) in
        return user.save(on: req)
    }
}

func updateHandler(_ req: Request) throws -> Future<User> {
    return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(User.self)) { (user, updatedUser) in
        user.name = updatedUser.name
        user.username = updatedUser.username
        return user.save(on: req)
    }
}

func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters.next(User.self).flatMap { (user) in
        return user.delete(on: req).transform(to: HTTPStatus.noContent)
    }
}
