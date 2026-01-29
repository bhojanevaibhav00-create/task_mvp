# Database, Models & Offline CRUD

---
## Demo Script Flow

- **Login**: Enter user ID and password.
- **Dashboard**: View overview stats. In "Recent Tasks", tap the filter icon and apply a filter by **Status** and **Priority**.
- **Add Task**: Use the quick action, fill in the details (Title, Priority, Due Date), and save.
- **My Tasks**: Navigate to the "My Tasks" screen and use the search bar to find the newly created task.
- **Notifications**: Tap the bell icon to view alerts for the new task.

---

## Migration & Upgrade Safety

### 1. Schema Versioning Strategy

The database schema is versioned using the `schemaVersion` getter in `AppDatabase` (`lib/data/database/database.dart`).

- **Current Version**: 8
- **Rule**: Every time a table structure changes (new column, new table), increment this version number by 1.

### 2. Handling Upgrades (Migration Strategy)

We use Drift's `MigrationStrategy` to handle upgrades safely without data loss.

- **Logic**: The `onUpgrade` callback receives the `from` (old) and `to` (new) version.
- **Implementation**: We check the `from` version and apply changes incrementally.
  ```dart
  if (from < 8) {
    // Apply changes introduced in version 8
    // Example: await m.addColumn(tasks, tasks.newColumn);
  }
  ```
- **Version 8 Update**:
  - Validated migration path for `ActivityLogs`.
  - Consolidated schema definitions.

- **Safety**: This ensures that users upgrading from version 1 directly to version 7 will execute all intermediate migration steps sequentially (or cumulatively if structured that way).

### 3. Developer Clean Reset

If you encounter schema mismatches during active development (e.g., "no such column" errors) and don't need to preserve data:

1. **Uninstall the App**: Long press -> App Info -> Storage -> Clear Data (or Uninstall).
2. **Rebuild**: Run `flutter run`.
3. **Regenerate Code**: If you changed dart files, run `dart run build_runner build --delete-conflicting-outputs`.

---

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
- **`updateTask(Task task)`**: Updates an existing task.
  - **Consistency**: Always updates `updatedAt`. Sets `completedAt` only when status is 'done' (clears it if reopened).
  - **Logic**: Handles status transitions and activity logging.
- **`getRecentActivity()`**: Fetches the last 20 activity logs for the dashboard.
- **`seedDatabase()`**: Populates the database with sample projects, tags, and tasks for testing.

---

### CollaborationRepository (`lib/data/repositories/collaboration_repository.dart`)

Manages project membership, task assignments, and user collaboration safety.

- **Member Management**:
  - **`addMember` / `removeMember`**: Adds or removes users. Includes checks to prevent removing the last owner.
  - **`updateMemberRole`**: Changes roles (Owner, Admin, Member). Prevents downgrading the last owner.
  - **`listAvailableUsersNotInProject`**: _New_ - Efficiently finds users eligible to be added to a project using subqueries.
- **Task Assignment**:
  - **`assignTask` / `unassignTask`**: Links tasks to users and logs the activity.
- **User Lookup**:
  - **`getUserById`**: Fetches user details.
  - **`searchUsers`**: Finds users by name for invitations.

---

### Run Code Generation

'''dart
Run `dart run build_runner build` to generate the database code (`database.g.dart`).
'''

---

### Backend Folder Structure

```
lib/data/
├── database/
│   ├── database.dart
│   └── database.g.dart
├── models/
│   ├── project_member.dart
│   ├── enums.dart
│   ├── project_role.dart
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
│   ├── collaboration_repository.dart
│   └── task_repository.dart
├── seed/
│   └── seed_data.dart
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

- **`project_role.dart`**:
  - Defines the `ProjectRole` enum (`owner`, `admin`, `member`) used for permission management.
  - Includes `label` getter for UI display and `fromString` factory for database serialization.

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
  - **Archiving**: Archived projects are excluded by default. Archiving does NOT delete tasks.
  - **Statistics**: Provides computed metrics like progress percentage and overdue counts for dashboards.

- **`notifications_repository.dart`**:
  - Manages system alerts and reminders.
  - Supports marking notifications as read and fetching unread counts.

- **`collaboration_repository.dart`**:
  - **Purpose**: Handles project membership and task assignment logic.
  - **Methods**: `assignTask`, `unassignTask`, `addMember`, `removeMember`, `updateMemberRole`, `listAvailableUsersNotInProject`, `searchUsers`.
  - **Features**: Enforces "Last Owner" safety constraints and triggers notifications/logs on assignment.
  - **Safety Rules**:
    - **Last Owner Protection**: To ensure project accessibility, the system prevents removing the last user with the `owner` role from a project. Similarly, the last owner cannot be downgraded to `admin` or `member` unless another owner exists.

### 3. Seed Data (`lib/data/seed_data.dart`)

- **`SeedData`**: A utility class that generates a list of sample `Task` objects.
  - **Usage**: Used by the "Seed Data" button in the UI to populate the database with tasks having various statuses, priorities, and due dates for testing purposes.

---

## Helper Methods & Utilities Reference

This section provides a comprehensive guide to the helper methods and utilities available in the project, categorized by their domain. These methods abstract complex logic, ensuring the UI remains clean and declarative.

### 1. Repository Helpers (Data Aggregation)

These methods perform complex database queries or aggregations to prepare data for the UI.

#### `ProjectRepository.watchProjectStatistics`

- **Location**: `lib/data/repositories/project_repository.dart`
- **Usage**: `StreamBuilder(stream: projectRepo.watchProjectStatistics(), ...)`
- **Purpose**: Real-time dashboard metrics.
- **Logic**: Joins `Projects` and `Tasks`. Calculates:
  - `progress`: (Completed Tasks / Total Tasks).
  - `overdueTasks`: Tasks where `dueDate < now` AND `status != done`.
  - `upcomingTasks`: Tasks where `dueDate > now`.

#### `CollaborationRepository.listAvailableUsersNotInProject`

- **Location**: `lib/data/repositories/collaboration_repository.dart`
- **Usage**: Populating the "Add Member" dialog.
- **Purpose**: Prevents duplicate memberships.
- **Logic**: `SELECT * FROM users WHERE id NOT IN (SELECT userId FROM project_members WHERE projectId = ?)`.

#### `TaskRepository.getRecentActivity`

- **Location**: `lib/data/repositories/task_repository.dart`
- **Usage**: Home screen "Recent Activity" feed.
- **Purpose**: Audit trail visualization.
- **Logic**: Returns the latest 20 `ActivityLogs` entries, sorted by time descending.

#### `CollaborationRepository.searchUsers`

- **Location**: `lib/data/repositories/collaboration_repository.dart`
- **Usage**: User search autocomplete.
- **Logic**: SQL `LIKE %query%` on the user name field.

### 2. Domain Logic Helpers (Extensions & Filters)

These helpers reside in the `models` folder and handle business rules.

#### `TaskFilters.apply`

- **Location**: `lib/data/models/task_filters.dart`
- **Usage**: `final visibleTasks = TaskFilters.apply(allTasks, query: 'bug', status: ...);`
- **Purpose**: Centralized filtering logic for search bars and sidebars.
- **Logic**:
  - Checks text match in `title` or `description`.
  - Checks date ranges (e.g., `isToday`, `isOverdue`).
  - Filters by `Priority` and `Tag`.

#### `TaskStatus.next` (Extension)

- **Location**: `lib/data/models/task_extensions.dart`
- **Usage**: `task.status.next()` inside a button callback.
- **Purpose**: Enforces the workflow state machine.
- **Logic**: `todo` → `inProgress` → `review` → `done`.

#### `TaskStatus.label` / `ProjectRole.label` (Extension)

- **Location**: `lib/data/models/task_extensions.dart` / `project_role.dart`
- **Usage**: `Text(task.status.label)`
- **Purpose**: Converts internal enum names (camelCase) to user-friendly display strings (Title Case).

### 3. Development Helpers

#### `SeedData.seed`

- **Location**: `lib/data/seed/seed_data.dart`
- **Usage**: Triggered by "Seed Database" button in Settings/DevTools.
- **Purpose**: Rapidly populates the app with realistic test data.
- **Logic**: Idempotent insert (checks for existence before adding) to prevent duplicates.

---

## Testing & Validation Notes

### Edge Case Validation

We validated the following scenarios to ensure data integrity and UI stability:

1. **Overdue Logic**
   - **Rule**: A task is "Overdue" if `dueDate` is strictly before `DateTime.now()` AND `status` is NOT 'done'.
   - **Validation**: Seeded tasks with past due dates appear in "Overdue" filters; completed past tasks do not.

2. **"No Due Date" Behavior**
   - **Rule**: Tasks with `dueDate = null` are treated as "Anytime" and never flagged as overdue.
   - **Validation**: Verified these tasks appear at the bottom of sorted lists and do not trigger overdue alerts.

3. **Reminder Null Safety**
   - **Rule**: The notification scheduler checks `reminderAt != null` and `reminderEnabled == true` before scheduling.
   - **Validation**: Creating tasks with `reminderEnabled = true` but no date defaults safely or is disabled in UI.

4. **Project Archiving**
   - **Rule**: Archiving a project sets `isArchived = true`. It does **NOT** delete associated tasks.
   - **Validation**:
     1. Archive a project.
     2. Verify project disappears from main list.
     3. Verify tasks still exist in the database (via "All Tasks" filter or DB inspection).

### Validation via Seed Data

We used the `SeedData` utility (`lib/data/seed/seed_data.dart`) to generate a comprehensive dataset including:

- Tasks with past/future/null due dates.
- Tasks in all priority levels.
- Projects with mixed active/completed tasks.
  This allowed rapid visual verification of filtering and sorting logic without manual entry.

**Note**: The seed script is designed to be **idempotent**. It checks for existing records (by name/title) before inserting, so you can safely press "Seed Data" multiple times during development without creating duplicate users, projects, or tasks.

---

## Recent Updates (v8)

### Database Migration & Integrity

- **Migration Path Validated**:
  - Conducted a full review of the database migration path from the initial version up to the current version 8.
  - Corrected a critical bug in the migration script for the `ActivityLogs` table that would have caused errors for users upgrading from versions prior to 7.

- **Schema Version Bumped to 8**:
  - The database schema version has been incremented to `8`.
  - This acts as a maintenance release to ensure schema integrity and consistency for all users, preventing potential crashes related to inconsistent database states during development.

- **Documentation Updated**:
  - The `README.md` has been updated to reflect the new version and the corrected migration logic.
  - The "Developer Clean Reset" steps have been re-validated and remain the recommended approach for resolving local development schema issues.

- **Collaboration Enhancements**:
  - Added helper methods to `CollaborationRepository` to support UI workflows:
    - `listAvailableUsersNotInProject(projectId)`: Efficiently filters users not yet in a project.
    - `getUserById(userId)`: Fetches individual user details.
    - `searchUsers(query)`: Allows searching users by name for invitations.
