class Tag {
  final String id;
  final String label;
  final int colorHex;

  Tag({required this.id, required this.label, required this.colorHex});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
    id: json['id'].toString(),
    label: json['label'],
    colorHex: json['colorHex'],
  );
}
