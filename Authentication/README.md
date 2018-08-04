## Vapor 3 Series II - Authentication
In [our previous article](https://medium.com/swift2go/vapor-3-series-i-crud-with-controllers-d7848f9c193b), we finished a simple RESTful API server with Vapor 3.
More specifically, we implemented `User` model to store data into a SQLite database and `UsersController` to handle interactions from a client.
Although our server has many great features now, it also has one problem: anyone can create new users and delete them.
In other words, there is no authentication on the endpoints to ensure that only known users can manipulate the database.
In this article, I am going to demonstrate how to store passwords and authenticated users, and how to protect our endpoints with HTTP basic and token authentications.
Please notice that this article is based on [the previous implementation](../CRUDControllers).

### User Password
Generally speaking, authentication is the process of verifying who someone is, and one common way to authenticate users is using username and password.

### Basic Authentication

### Token Authentication
