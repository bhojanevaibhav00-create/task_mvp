# Database, Models & Offline CRUD

Task Completed :-

1. Finalise data models:
   Users, Projects, Tasks, Status, Priority, Tags
2. Implement offline-first local database layer.
3. Build repositories for CRUD operations.
4. Implement task status flow and filtering.
5. Provide seed/sample data for testing.
6. Integrate UI with new logic foir Testing.

## Recent Updates (Activity Logs & Advanced Filtering)

The following features have been implemented to enhance the MVP:

### 1. Activity Logging (MVP)

- **New Table**: `ActivityLogs` table added to track user actions.
- **Tracking**: The `TaskRepository` now automatically logs:
  - Task Creation
  - Task Editing (Title/Description/Priority)
  - Status Changes (e.g., Todo -> Done)
  - Task Completion
  - Project Moves
- **Read Access**: `getRecentActivity()` method exposed to fetch the latest 20 logs for the Dashboard.

### 2. Advanced Filtering & Sorting

- **Database-Level**: Filtering is now performed efficiently at the database query level using Drift.
- **Supported Filters**:
  - Status (Todo, InProgress, Done, etc.)
  - Priority (Low, Medium, High)
  - Due Date Range (From/To)
  - Tags & Projects
- **Sorting Options**:
  - Due Date (Ascending)
  - Priority (Descending)
  - Updated At (Descending)

### 3. Enhanced Seed Data

- The `SeedData` utility now generates Projects, Tags, mixed Tasks (Overdue/Upcoming), and sample Activity Logs for immediate UI testing.
- Also added more sample data.

### 4. UI Integration & Status Flow

- **Task Providers**: Updated `task_providers.dart` to expose specific providers for filters (priority, tags, projects, date ranges) and activity logs, simplifying UI integration.
- **Status Flow**: Implemented logic to handle task status transitions with automatic timestamp management:
  - `created_at`: Set automatically on creation.
  - `updated_at`: Refreshed on every update.
  - `completed_at`: Set when status changes to 'done', cleared if reopened.

## Database Schema Overview

The application uses `drift` for the local SQLite database. Below is the schema definition:

### Tables

**1. Tasks**

- `id`: Integer (Primary Key, Auto Increment)
- `title`: Text (1-50 chars)
- `description`: Text (Nullable)
- `status`: Text (Nullable) - 'pending' or 'completed'
- `dueDate`: DateTime (Nullable)
- `priority`: Integer (Nullable) - 1 (Low), 2 (Medium), 3 (High)
- `projectId`: Integer (Nullable) - Foreign Key to Projects
- `tagId`: Integer (Nullable) - Foreign Key to Tags
- `createdAt`: DateTime (Default: Now)
- `updatedAt`: DateTime (Nullable)
- `completedAt`: DateTime (Nullable)

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

**5. ActivityLogs**

- `id`: Integer (Primary Key, Auto Increment)
- `action`: Text (e.g., 'created', 'completed')
- `description`: Text (Nullable)
- `timestamp`: DateTime (Default: Now)

## Development Setup

### 1. Run Migrations / Code Generation

This project uses `drift` for the database. If you modify the schema in `lib/data/database/database.dart`, you must regenerate the code:

```bash
dart run build_runner build
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

I have just created a app UI to test the working and you can change it as you see fit.
In this the task stauts is shown as done and undone but the model provides a todo`->`inProgress`->`review`->`done` so you can change it too.
and also i have added a comments on how to use the model and repo. so follow it.

<video src="https://github.com/user-attachments/assets/10fb0567-cc36-4ea6-9059-7ebd356d6734" width="230" height="1500" controls></video>

<img width="230" height="1645" alt="Image" src="https://github.com/user-attachments/assets/a266c199-9aa8-4c25-ac55-135ed4b0598f" />
<img width="230" height="1647" alt="Image" src="https://github.com/user-attachments/assets/2370d418-a0b1-4b5d-8d6b-73cfe1d18f80" />

<img width="1919" height="1020" alt="Image" src="https://github.com/user-attachments/assets/39984aff-bbe2-495f-a97a-2ed68094ba6a" />

<img width="1878" height="915" alt="Image" src="https://github.com/user-attachments/assets/34c063a9-4ed6-4a72-82fe-10be5d213615" />
