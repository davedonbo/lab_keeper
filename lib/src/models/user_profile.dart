class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? major;
  final int? yearGroup;
  final String? phone;                  // ← NEW

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.major,
    this.yearGroup,
    this.phone,                         // ← NEW
  });

  factory UserProfile.fromJson(String id, Map<String, dynamic> json) =>
      UserProfile(
        uid: id,
        name: json['name'],
        email: json['email'],
        role: json['role'],
        major: json['major'],
        yearGroup: json['yearGroup'],
        phone: json['phone'],           // ← NEW
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'role': role,
    'major': major,
    'yearGroup': yearGroup,
    'phone': phone,                 // ← NEW
  };
}
