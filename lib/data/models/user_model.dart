class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'], name: json['name']);
}

// to use this model, import this file where needed and use User.fromJson(yourJsonMap) to parse a User object.
// example: final user = User.fromJson({'id': 'u1', 'name': 'Alice');
