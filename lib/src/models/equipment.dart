class Equipment {
  final String id;           // Firestore doc‑ID
  final String name;

  Equipment({required this.id, required this.name});

  factory Equipment.fromJson(String id, Map<String, dynamic> json) =>
      Equipment(id: id, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'name': name};
}
