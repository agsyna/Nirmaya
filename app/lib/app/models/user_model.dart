class User {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String profileImageUrl;
  final String? email;
  final String? phone;
  final String? type;
  final String? bloodGroup;
  final double? height;
  final double? weight;
  final String? patientId;
  final bool? emergencySosEnabled;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.profileImageUrl,
    this.email,
    this.phone,
    this.type,
    this.bloodGroup,
    this.height,
    this.weight,
    this.patientId,
    this.emergencySosEnabled,
  });

  factory User.fromLoginJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? {};
    final patientData = json['patient'] ?? {};

    return User(
      id: userData['userId'] ?? '',
      name: userData['name'] ?? '',
      age: userData['age'] ?? 0,
      gender: userData['gender'] ?? '',
      profileImageUrl: '',
      email: userData['email'],
      phone: userData['phone'],
      type: userData['type'],
      bloodGroup: patientData['bloodGroup'],
      height: (patientData['height'] as num?)?.toDouble(),
      weight: (patientData['weight'] as num?)?.toDouble(),
      patientId: patientData['patientId'],
      emergencySosEnabled: patientData['emergencySosEnabled'],
    );
  }

  factory User.fromProfileJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? {};
    final patientData = json['patient'] ?? {};

    return User(
      id: userData['userId'] ?? '',
      name: userData['name'] ?? '',
      age: userData['age'] ?? 0,
      gender: userData['gender'] ?? '',
      profileImageUrl: '',
      email: userData['email'],
      phone: userData['phone'],
      type: userData['type'],
      bloodGroup: patientData['bloodGroup'],
      height: (patientData['height'] as num?)?.toDouble(),
      weight: (patientData['weight'] as num?)?.toDouble(),
      patientId: patientData['patientId'],
      emergencySosEnabled: patientData['emergencySosEnabled'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'profileImageUrl': profileImageUrl,
        'email': email,
        'phone': phone,
        'type': type,
        'bloodGroup': bloodGroup,
        'height': height,
        'weight': weight,
        'patientId': patientId,
        'emergencySosEnabled': emergencySosEnabled,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      email: json['email'],
      phone: json['phone'],
      type: json['type'],
      bloodGroup: json['bloodGroup'],
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      patientId: json['patientId'],
      emergencySosEnabled: json['emergencySosEnabled'],
    );
  }
}
