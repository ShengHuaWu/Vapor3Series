## Vapor 3 Series IV - Relationship
In [our previous article](https://medium.com/swift2go/vapor-3-series-iii-testing-b192be079c9e), we enabled testing and wrote unit tests for each endpoint.
Besides, we managed to run these tests on Linux environment with Docker as well.
Testing allows us to develop and evolve our application quickly, because the test suite lets us verify everything still works as we change our codebase.
In this article, we are going to explore two different kind of relationships among our models --- parent-child and sibling relationships.
A parent-child relationship describes an ownership of one or more models, and it is known as one-to-one and one-to-many relationships.
On the other hand, a sibling relationship describes links between two models, and it is known as many-to-many relationship.

Please notice that this article will base on [the previous implementation](../Testing).

### Preparation
Before diving into relationships, we have to create two new model types and their controllers.
As usual, use Terminal to create the corresponding files and regenerate our Xcode project with the following lines.
```
touch Sources/App/Models/Pet.swift Sources/App/Models/Category.swift
touch Sources/App/Controllers/PetsController.swift Sources/App/Controllers/CategoriesController.swift
vapor xcode -y
```

### Parent-Child Relationship

### Sibling Relationship

### Conclusion
