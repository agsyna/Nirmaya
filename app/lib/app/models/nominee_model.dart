class Nominee {
  final String id;
  final String name;
  final String email;

  Nominee({required this.id, required this.name, required this.email});

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  Nominee copyWith({String? id, String? name, String? email}) {
    return Nominee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
