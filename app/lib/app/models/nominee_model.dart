class Nominee {
  final String id;
  final String name;
  final String email;
  final String phone;

  Nominee({required this.id, required this.name, required this.email,required this.phone});

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      id: json['nomineeId']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone};

  Nominee copyWith({String? id, String? name, String? email, String? phone}) {
    return Nominee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
