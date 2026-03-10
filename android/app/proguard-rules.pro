# Flutter/Drift specific rules
# This rule prevents R8 from removing the names of your enums, which are needed
# by drift's EnumNameConverter and other serialization methods that rely on enum.name.
# Without this, looking up an enum by its string name (e.g., 'done') will fail in release builds.
-keep public enum com.example.task_mvp.data.models.enums.** { *; }
-keep public enum com.example.task_mvp.data.models.project_role.** { *; }

# It's also a good practice to keep your data models if they are used with reflection.
-keep class com.example.task_mvp.data.models.** { *; }