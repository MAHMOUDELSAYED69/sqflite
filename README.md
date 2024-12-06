# SqlDb - SQLite Database Handler for Flutter

This Flutter project provides a reusable, singleton class, `SqlDb`, to handle SQLite database operations using the `sqflite` package. The class manages the creation, initialization, and CRUD operations on a database, allowing developers to define their own table schemas dynamically.

## Features

- **Singleton Design Pattern**: Ensures only one instance of the database is used throughout the app.
- **Database Initialization**: Automatically initializes the database and creates tables based on user-defined schemas.
- **Flexible Table Management**: Add custom table definitions that will be used to create tables when the database is initialized.
- **CRUD Operations**: Includes methods for creating, reading, updating, and deleting records.
- **User Management**: Allows inserting and retrieving users, with support for username and password validation.
- **Invoice Management**: Supports saving invoices and generating the next invoice number for a user.
  
## Getting Started

### Prerequisites

Ensure you have Flutter installed and set up on your machine. You will also need to include the following dependencies in your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.0.0+4
  path: ^1.8.3
```
### Installation
Clone the repository or copy the SqlDb class into your Flutter project.

Initialize the database in your main application file. You can do this using an anonymous object:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SqlDb().initializeDatabase();
  runApp(MyApp());
}
```
## Notice

You can easily customize the database structure by modifying the table definitions in the `_onCreate` method. This makes `SqlDb` suitable for various applications, from simple apps to complex systems with unique data needs.

## Contact

For any questions or feedback, please reach out via email: [mahmoudelsayed.dev@gmail.com](mahmoudelsayed.dev@gmail.com)
