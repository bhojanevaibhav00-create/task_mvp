# Database, Models & Offline CRUD

## Database Schema Overview

The application uses `drift` for the local SQLite database. Below is the schema definition:

### Tables

**1. Tasks**

- `id`: Integer (Primary Key, Auto Increment)
- `title`: Text (1-50 chars)
- `description`: Text (Nullable)
- `status`: Text (Nullable) - 'pending' or 'completed'
- `dueDate`: DateTime (Nullable)
- `dueTime`: Text (Nullable)
- `reminderAt`: DateTime (Nullable)
- `reminderEnabled`: Boolean (Default: False)
- `priority`: Integer (Nullable) - 1 (Low), 2 (Medium), 3 (High)
- `projectId`: Integer (Nullable) - Foreign Key to Projects
- `tagId`: Integer (Nullable) - Foreign Key to Tags
- `createdAt`: DateTime (Default: Now)
- `updatedAt`: DateTime (Nullable)
- `completedAt`: DateTime (Nullable)
- `assigneeId`: Integer (Nullable) - Foreign Key to Users

**2. Projects**

- `id`: Integer (Primary Key, Auto Increment)
- `name`: Text (1-50 chars)
- `description`: Text (Nullable)
- `color`: Integer (Nullable)
- `isArchived`: Boolean (Default: False)
- `createdAt`: DateTime (Default: Now)
- `updatedAt`: DateTime (Nullable)

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
- `taskId`: Integer (Nullable)
- `projectId`: Integer (Nullable)
- `timestamp`: DateTime (Default: Now)

**6. Notifications**

- `id`: Integer (Primary Key, Auto Increment)
- `type`: Text (e.g., 'reminder', 'system')
- `title`: Text
- `message`: Text
- `taskId`: Integer (Nullable) - Foreign Key to Tasks
- `projectId`: Integer (Nullable) - Foreign Key to Projects
- `createdAt`: DateTime (Default: Now)
- `isRead`: Boolean (Default: False)

**7. ProjectMembers**

- `projectId`: Integer (Foreign Key to Projects)
- `userId`: Integer (Foreign Key to Users)
- `role`: Text (e.g., 'admin', 'member')
- `joinedAt`: DateTime (Default: Now)
- Primary Key: (projectId, userId)

---

## Key Repository Methods

### TaskRepository (`lib/data/repositories/task_repository.dart`)

The `TaskRepository` is the primary entry point for task management.

- **`watchTasks`**: The core method for the UI. Returns a `Stream<List<Task>>` that updates automatically.
  - **Parameters**:
    - `statuses`: Filter by list of status strings (e.g., `['todo', 'in_progress']`).
    - `priority`: Filter by priority level (1=Low, 2=Medium, 3=High).
    - `fromDate` / `toDate`: Filter tasks due within a specific range.
    - `projectId`: Filter by project.
    - `tagId`: Filter by tag.
    - `sortBy`: Sort key (default: `updated_at_desc`).
- **`createTask(TasksCompanion task)`**: Adds a new task and logs the creation activity.
- **`updateTask(Task task)`**: Updates an existing task. Handles status transitions and `completedAt` timestamps automatically.
- **`getRecentActivity()`**: Fetches the last 20 activity logs for the dashboard.
- **`seedDatabase()`**: Populates the database with sample projects, tags, and tasks for testing.

---

### Run Code Generation

## Run `dart run build_runner build` to generate the database code (`database.g.dart`).

### Backend Folder Structure

```
lib/data/
├── database/
│   ├── database.dart
│   └── database.g.dart
├── models/
│   ├── project_member.dart
│   ├── enums.dart
│   ├── project_model.dart
│   ├── tag_model.dart
│   ├── task_extensions.dart
│   ├── task_filters.dart
│   ├── task_model.dart
│   └── user_model.dart
├── repositories/
│   ├── notifications_repository.dart
│   ├── i_task_repository.dart
│   ├── project_repository.dart
│   └── task_repository.dart
├── seed/
    └── seed_data.dart
```

---

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

- **`i_task_repository.dart`**:

  - Defines the abstract contract for task operations.
  - Decouples the UI from the specific database implementation, facilitating testing and future data source changes.

- **`task_repository.dart`**:

  - **`watchAllTasks()`**: Returns a `Stream<List<Task>>` that automatically emits new values when the database changes.
  - **`createTask`, `updateTask`, `deleteTask`**: Standard CRUD operations.
  - **`deleteAllTasks()`**: Utility for clearing data during testing.
  - **Activity Logging**: Automatically logs actions (create, update, complete) to `ActivityLogs`.

- **`project_repository.dart`**:

  - Manages `Project` entities with support for archiving and color coding.
  - **Statistics**: Provides computed metrics like progress percentage and overdue counts for dashboards.

- **`notifications_repository.dart`**:
  - Manages system alerts and reminders.
  - Supports marking notifications as read and fetching unread counts.

### 3. Seed Data (`lib/data/seed_data.dart`)

- **`SeedData`**: A utility class that generates a list of sample `Task` objects.
  - **Usage**: Used by the "Seed Data" button in the UI to populate the database with tasks having various statuses, priorities, and due dates for testing purposes.

---

## Migration & Upgrade Safety

### 1. Schema Versioning Strategy

The database schema is versioned using the `schemaVersion` getter in `AppDatabase` (`lib/data/database/database.dart`).

- **Current Version**: 7
- **Rule**: Every time a table structure changes (new column, new table), increment this version number by 1.

### 2. Handling Upgrades (Migration Strategy)

We use Drift's `MigrationStrategy` to handle upgrades safely without data loss.

- **Logic**: The `onUpgrade` callback receives the `from` (old) and `to` (new) version.
- **Implementation**: We check the `from` version and apply changes incrementally.
  ```dart
  if (from < 7) {
    // Apply changes introduced in version 7
    await m.createTable(projectMembers);
    await m.addColumn(tasks, tasks.assigneeId);
  }
  ```
- **Safety**: This ensures that users upgrading from version 1 directly to version 7 will execute all intermediate migration steps sequentially (or cumulatively if structured that way).

### 3. Developer Clean Reset

If you encounter schema mismatches during active development (e.g., "no such column" errors) and don't need to preserve data:

1. **Uninstall the App**: Long press -> App Info -> Storage -> Clear Data (or Uninstall).
2. **Rebuild**: Run `flutter run`.
3. **Regenerate Code**: If you changed dart files, run `dart run build_runner build --delete-conflicting-outputs`.

---

## Testing & Validation Notes

### Validated Edge Cases

1. **Null Dates**: Verified that tasks with no due date appear correctly in "No Date" filters and don't crash sorting logic.
2. **Status Transitions**:
   - _Scenario_: Move Task from 'Todo' -> 'Done' -> 'Todo'.
   - _Result_: `completedAt` is set, then cleared. `updatedAt` updates on both actions.
3. **Migration Resilience**:
   - _Scenario_: Installed app with Schema v1, then upgraded to v7.
   - _Result_: New tables (`ActivityLogs`, `Notifications`) were created, and existing Tasks table received new columns (`assigneeId`) without losing existing tasks.
4. **Archived Projects**:
   - _Scenario_: Archive a project with active tasks.
   - _Result_: Tasks remain in DB but project is hidden from default lists. Tasks are still accessible via "All Tasks" if filters allow.
