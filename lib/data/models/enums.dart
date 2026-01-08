enum TaskStatus { todo, inProgress, completed, blocked }

enum Priority { low, medium, high, urgent }

class Tag {
  final String id;
  final String label;
  final int colorHex;

  Tag({required this.id, required this.label, required this.colorHex});

  factory Tag.fromJson(Map<String, dynamic> json) =>
      Tag(id: json['id'], label: json['label'], colorHex: json['color_hex']);
}

//to use enums, import this file where needed and use TaskStatus.values.byName('enumNameString') to get the enum value.
//example: final status = TaskStatus.values.byName('inProgress');
//similarly for Priority enum.
