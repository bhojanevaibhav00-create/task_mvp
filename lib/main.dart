import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;

import 'data/database/database.dart';
import 'data/repositories/project_repository.dart';
import 'data/repositories/task_repository.dart';

// Import domain models with aliases to avoid conflicts with Drift generated classes
import 'data/models/task_model.dart' as domain_task;
import 'data/models/project_model.dart' as domain_project;
import 'data/models/enums.dart' as domain_enums;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final db = AppDatabase();
    final taskRepo = TaskRepository(db);
    final projectRepo = ProjectRepository(db);

    print('--- Database CRUD Check ---');

    // 1. Create (Insert)
    final insertedId = await taskRepo.createTask(
      TasksCompanion.insert(
        title: 'CRUD Task',
        description: const Value('Testing database operations'),
        status: const Value('todo'),
      ),
    );
    print('1. Created Task with ID: $insertedId');

    // 2. Read (Select)
    final dbTask = await taskRepo.getTaskById(insertedId);
    if (dbTask != null) {
      print('2. Read Task: "${dbTask.title}" with status: ${dbTask.status}');

      // Demonstrate using the Domain Model
      // Converting Drift 'Task' to Domain 'Task'
      try {
        final domainTask = domain_task.Task(
          id: dbTask.id.toString(),
          title: dbTask.title,
          description: dbTask.description ?? '',
          status: dbTask.status != null
              ? domain_enums.TaskStatus.values.byName(dbTask.status!)
              : domain_enums.TaskStatus.todo,
          priority: domain_enums.Priority.medium, // Defaulting for demo
          tags: [],
          dueDate: dbTask.dueDate,
        );
        print(
          '   -> Domain Model mapped: ${domainTask.title} (ID: ${domainTask.id})',
        );
      } catch (e) {
        print('   -> Domain mapping error: $e');
      }

      // 3. Update
      // We use copyWith to modify the object and pass it to the repo's update method
      final taskToUpdate = dbTask.copyWith(
        title: 'Updated CRUD Task',
        status: const Value('completed'), // Matches TaskStatus.completed.name
      );
      await taskRepo.updateTask(taskToUpdate);

      final updatedTask = await taskRepo.getTaskById(insertedId);
      print(
        '3. Updated Task: "${updatedTask?.title}" with status: ${updatedTask?.status}',
      );
    }

    // 4. Delete
    await taskRepo.deleteTask(insertedId);
    final allTasks = await taskRepo.getAllTasks();
    print('4. Deleted Task. Remaining count: ${allTasks.length}');

    // Project Check
    print('--- Project Repo Check ---');
    final projectId = await projectRepo.createProject(
      ProjectsCompanion.insert(
        title: 'Repo Project',
        createdAt: DateTime.now(),
      ),
    );
    print('Project created: $projectId');
    final projects = await projectRepo.getAllProjects();

    if (projects.isNotEmpty) {
      final p = projects.first;
      final domainProject = domain_project.Project(
        id: p.id.toString(),
        title: p.title,
        createdAt: p.createdAt,
      );
      print('   -> Domain Project mapped: ${domainProject.title}');
    }
    print('Projects count: ${projects.length}');
    await projectRepo.deleteProject(projectId);
    print('Project deleted');
  } catch (e, stack) {
    print('--- Model Error: $e ---');
    print(stack);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
