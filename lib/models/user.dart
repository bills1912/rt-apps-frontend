class User {
  final int id;
  final String? email;
  final String name;
  final String role;
  final String kk;
  final DateTime createdAt;

  User({
    required this.id,
    this.email,
    required this.name,
    required this.role,
    required this.kk,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'],
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      kk: json['kk'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'kk': kk,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
