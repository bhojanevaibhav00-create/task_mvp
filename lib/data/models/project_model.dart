class Project {
  final String id;
  final String title;
  final DateTime createdAt;

  Project({required this.id, required this.title, required this.createdAt});

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

// to use this model, import this file where needed and use Project.fromJson(yourJsonMap) to parse a Project object.
// example: final project = Project.fromJson({'id': 'p1', 'title': 'Project A', 'created_at': DateTime.now()});
