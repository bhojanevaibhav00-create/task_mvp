# Database, Models & Offline CRUD

## Hi im Ajinkya working on this project.

Task Completed :-

1. Finalise data models:
   Users, Projects, Tasks, Status, Priority, Tags
2. Implement offline-first local database layer.
3. Build repositories for CRUD operations.
4. Implement task status flow and filtering.
5. Provide seed/sample data for testing.
6. Integrate UI with new logic foir Testing.

## Database Schema Overview

The application uses `drift` for the local SQLite database. Below is the schema definition:

### Tables

**1. Tasks**

- `id`: Integer (Primary Key, Auto Increment)
- `title`: Text (1-50 chars)
- `description`: Text (Nullable)
- `status`: Text (Nullable)
- `dueDate`: DateTime (Nullable)
- `priority`: Integer (Nullable)
- `projectId`: Integer (Nullable, Foreign Key to Projects)

**2. Projects**

- `id`: Integer (Primary Key, Auto Increment)
- `title`: Text (1-50 chars)
- `createdAt`: DateTime

**3. Users**

- `id`: Integer (Primary Key, Auto Increment)
- `name`: Text (1-50 chars)

**4. Tags**

- `id`: Integer (Primary Key, Auto Increment)
- `label`: Text (1-30 chars)
- `colorHex`: Integer

## Integration Guide (How to use this backend in your project)

Just follow this steps to integrate it to app :-

### 1. Add Dependencies

Add the following packages to your `pubspec.yaml`:

```yaml
dependencies:
  drift: ^2.24.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.2
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.24.0
  build_runner: ^2.4.8
```

### 2. Copy Backend Files

Copy the entire `lib/data` folder into your project. This folder contains everything you need:

- **Database**: `lib/data/database/` (Drift database definition)
- **Models**: `lib/data/models/` (Domain entities, Enums, Filters)
  - _Note: You may need to update the `import` statements if your package name is different._
- **Repositories**: `lib/data/repositories/` (CRUD operations)
- **Seed Data**: `lib/data/seed_data.dart` (Sample data)

### 3. Run Code Generation

Run `dart run build_runner build` to generate the database code (`database.g.dart`).

### Backend Folder Structure

```
lib/data/
├── database/
│   ├── database.dart
│   └── database.g.dart
├── models/
│   ├── enums.dart
│   ├── project_model.dart
│   ├── tag_model.dart
│   ├── task_extensions.dart
│   ├── task_filters.dart
│   ├── task_model.dart
│   └── user_model.dart
├── repositories/
│   ├── project_repository.dart
│   └── task_repository.dart
├── seed/
└── seed_data.dart
```

## Project Structure & Implementation Details

### 1. Data Models (`lib/data/models/`)

These files define the domain logic and data structures used throughout the app.

- **`task_model.dart`**: The domain entity representing a Task. It acts as a bridge between the database entities and the UI.
- **`enums.dart`**: Defines the core enumerations for the application:
  - `TaskStatus`: Represents the lifecycle (`todo` -> `inProgress` -> `review` -> `done`).
  - `Priority`: Levels of importance (`low`, `medium`, `high`, `critical`).
  - `SortCriteria`: Options for sorting the task list in the UI.
- **`task_filters.dart`**: Contains the business logic for filtering tasks.
  - **Usage**: `TaskFilters.apply(tasks, status: ..., isOverdue: ...)`
  - Handles complex filtering logic like date ranges (today, this week) and text search.
- **`task_extensions.dart`**: Adds behavior to the `TaskStatus` enum.
  - **`next`**: Implements the state machine logic to determine the next status in the workflow.
  - **`label`**: Returns a user-friendly string for display.

### 2. Repositories (`lib/data/repositories/`)

The repository pattern is used to abstract the data source (Drift Database).

- **`task_repository.dart`**:
  - **`watchAllTasks()`**: Returns a `Stream<List<Task>>` that automatically emits new values when the database changes.
  - **`createTask`, `updateTask`, `deleteTask`**: Standard CRUD operations.
  - **`deleteAllTasks()`**: Utility for clearing data during testing.
- **`project_repository.dart`**:
  - Manages `Project` entities, allowing tasks to be organized into groups.

### 3. Seed Data (`lib/data/seed_data.dart`)

- **`SeedData`**: A utility class that generates a list of sample `Task` objects.
  - **Usage**: Used by the "Seed Data" button in the UI to populate the database with tasks having various statuses, priorities, and due dates for testing purposes.


# Screenshots of Completed task :

<img width="1919" height="1020" alt="Image" src="https://github.com/user-attachments/assets/39984aff-bbe2-495f-a97a-2ed68094ba6a" />

<img width="1878" height="915" alt="Image" src="https://github.com/user-attachments/assets/34c063a9-4ed6-4a72-82fe-10be5d213615" />
