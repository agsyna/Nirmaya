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
  final String? doctorId;
  final String? licenseNumber;
  final String? specialization;
  final bool? doctorVerified;

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
    this.doctorId,
    this.licenseNumber,
    this.specialization,
    this.doctorVerified,
  });

  factory User.fromLoginJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? {};
    final patientData = json['patient'] ?? {};
    final doctorData = json['doctor'] ?? {};

    return User(
      id: userData['userId'] ?? '',
      name: userData['name'] ?? '',
      age: _parseAge(userData['age']),
      gender: userData['gender'] ?? '',
      profileImageUrl: '',
      email: userData['email'],
      phone: userData['phone'],
      type: userData['type'],
      bloodGroup: patientData['bloodGroup'],
      height: _parseDouble(patientData['height']),
      weight: _parseDouble(patientData['weight']),
      patientId: patientData['patientId'],
      emergencySosEnabled: patientData['emergencySosEnabled'],
      doctorId: doctorData['doctorId'],
      licenseNumber: doctorData['licenseNumber'],
      specialization: doctorData['specialization'],
      doctorVerified: doctorData['verified'],
    );
  }

  factory User.fromProfileJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? {};
    final patientData = json['patient'] ?? {};
    final doctorData = json['doctor'] ?? {};

    return User(
      id: userData['userId'] ?? '',
      name: userData['name'] ?? '',
      age: _parseAge(userData['age']),
      gender: userData['gender'] ?? '',
      profileImageUrl: '',
      email: userData['email'],
      phone: userData['phone'],
      type: userData['type'],
      bloodGroup: patientData['bloodGroup'],
      height: _parseDouble(patientData['height']),
      weight: _parseDouble(patientData['weight']),
      patientId: patientData['patientId'],
      emergencySosEnabled: patientData['emergencySosEnabled'],
      doctorId: doctorData['doctorId'],
      licenseNumber: doctorData['licenseNumber'],
      specialization: doctorData['specialization'],
      doctorVerified: doctorData['verified'],
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
        'doctorId': doctorId,
        'licenseNumber': licenseNumber,
        'specialization': specialization,
        'doctorVerified': doctorVerified,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: _parseAge(json['age']),
      gender: json['gender'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      email: json['email'],
      phone: json['phone'],
      type: json['type'],
      bloodGroup: json['bloodGroup'],
      height: _parseDouble(json['height']),
      weight: _parseDouble(json['weight']),
      patientId: json['patientId'],
      emergencySosEnabled: json['emergencySosEnabled'],
      doctorId: json['doctorId'],
      licenseNumber: json['licenseNumber'],
      specialization: json['specialization'],
      doctorVerified: json['doctorVerified'],
    );
  }

  static int _parseAge(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
