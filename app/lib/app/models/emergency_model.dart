class Emergency {
  final String sosId;
  final String status; // active, resolved
  final String serviceType; // ambulance, police, fire, medical-support, other
  final String description;
  final String latitude;
  final String longitude;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final AffectedPatientProfile? affectedPatientProfile;
  final CriticalInfoShared? criticalInfoShared;
  final LatestHealthData? latestHealthData;
  final String? message;
  final int? ambulanceEta;

  Emergency({
    required this.sosId,
    required this.status,
    required this.serviceType,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.resolvedAt,
    this.affectedPatientProfile,
    this.criticalInfoShared,
    this.latestHealthData,
    this.message,
    this.ambulanceEta,
  });

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';

  factory Emergency.fromJson(Map<String, dynamic> json) {
    return Emergency(
      sosId: json['sosId'] ?? json['id'] ?? '',
      status: json['status'] ?? 'active',
      serviceType: json['serviceType'] is List
          ? json['serviceType'].join(', ')
          : (json['serviceType']?.toString() ??
                json['serviceTypes']?.toString() ??
                ''),
      description: json['description'] ?? '',
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      affectedPatientProfile: json['affectedPatientProfile'] != null
          ? AffectedPatientProfile.fromJson(json['affectedPatientProfile'])
          : null,
      criticalInfoShared: json['criticalInfoShared'] != null
          ? CriticalInfoShared.fromJson(json['criticalInfoShared'])
          : null,
      latestHealthData: json['latestHealthData'] != null
          ? LatestHealthData.fromJson(json['latestHealthData'])
          : null,
      message: json['message'],
      ambulanceEta: json['ambulanceEta'],
    );
  }

  Map<String, dynamic> toJson() => {
    'sosId': sosId,
    'status': status,
    'serviceType': serviceType,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'affectedPatientProfile': affectedPatientProfile?.toJson(),
    'criticalInfoShared': criticalInfoShared?.toJson(),
    'latestHealthData': latestHealthData?.toJson(),
    'message': message,
    'ambulanceEta': ambulanceEta,
  };
}

class AffectedPatientProfile {
  final int age;
  final String gender;
  final String bloodGroup;
  final int? height;
  final int? weight;

  AffectedPatientProfile({
    required this.age,
    required this.gender,
    required this.bloodGroup,
    this.height,
    this.weight,
  });

  factory AffectedPatientProfile.fromJson(Map<String, dynamic> json) {
    return AffectedPatientProfile(
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      bloodGroup: json['bloodGroup'] ?? 'Unknown',
      height: json['height'],
      weight: json['weight'],
    );
  }

  Map<String, dynamic> toJson() => {
    'age': age,
    'gender': gender,
    'bloodGroup': bloodGroup,
    'height': height,
    'weight': weight,
  };
}

class CriticalInfoShared {
  final String bloodGroup;
  final int age;
  final String gender;
  final int? height;
  final int? weight;
  final List<Allergy> allergies;
  final List<ChronicCondition> chronicConditions;

  CriticalInfoShared({
    required this.bloodGroup,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    required this.allergies,
    required this.chronicConditions,
  });

  factory CriticalInfoShared.fromJson(Map<String, dynamic> json) {
    return CriticalInfoShared(
      bloodGroup: json['bloodGroup'] ?? '',
      age: json['age'] ?? 0,
      gender: (json['gender'] ?? '').toString().trim(),
      height: json['height'],
      weight: json['weight'],
      allergies:
          (json['allergies'] as List?)
              ?.map((e) => Allergy.fromJson(e))
              .toList() ??
          [],
      chronicConditions:
          (json['chronicConditions'] as List?)
              ?.map((e) => ChronicCondition.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'bloodGroup': bloodGroup,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
    'allergies': allergies.map((e) => e.toJson()).toList(),
    'chronicConditions': chronicConditions.map((e) => e.toJson()).toList(),
  };
}

class Allergy {
  final String name;
  final String severity;
  final String description;

  Allergy({
    required this.name,
    required this.severity,
    required this.description,
  });

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      name: json['name'] ?? '',
      severity: json['severity'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'severity': severity,
    'description': description,
  };
}

class ChronicCondition {
  final String name;
  final String status;
  final String? diagnosisDate;
  final String notes;

  ChronicCondition({
    required this.name,
    required this.status,
    this.diagnosisDate,
    required this.notes,
  });

  factory ChronicCondition.fromJson(Map<String, dynamic> json) {
    return ChronicCondition(
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      diagnosisDate: json['diagnosisDate'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status,
    'diagnosisDate': diagnosisDate,
    'notes': notes,
  };
}

class LatestHealthData {
  final String id;
  final String bloodPressure;
  final int bloodGlucose;
  final int heartRate;
  final double temperature;
  final int weight;
  final DateTime recordedAt;

  LatestHealthData({
    required this.id,
    required this.bloodPressure,
    required this.bloodGlucose,
    required this.heartRate,
    required this.temperature,
    required this.weight,
    required this.recordedAt,
  });

  factory LatestHealthData.fromJson(Map<String, dynamic> json) {
    return LatestHealthData(
      id: json['id'] ?? '',
      bloodPressure: json['bloodPressure'] ?? '0/0',
      bloodGlucose: json['bloodGlucose'] ?? 0,
      heartRate: json['heartRate'] ?? 0,
      temperature: (json['temperature'] ?? 0).toDouble(),
      weight: json['weight'] ?? 0,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bloodPressure': bloodPressure,
    'bloodGlucose': bloodGlucose,
    'heartRate': heartRate,
    'temperature': temperature,
    'weight': weight,
    'recordedAt': recordedAt.toIso8601String(),
  };
}
