class HealthData {
  final String id;
  final String patientId;
  final String? bloodPressure;
  final int? bloodGlucose;
  final int? heartRate;
  final double? temperature;
  final double? weight;
  final String? notes;
  final DateTime recordedAt;
  final DateTime createdAt;

  HealthData({
    required this.id,
    required this.patientId,
    this.bloodPressure,
    this.bloodGlucose,
    this.heartRate,
    this.temperature,
    this.weight,
    this.notes,
    required this.recordedAt,
    required this.createdAt,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      bloodPressure: json['bloodPressure'],
      bloodGlucose: _parseInt(json['bloodGlucose']),
      heartRate: _parseInt(json['heartRate']),
      temperature: _parseDouble(json['temperature']),
      weight: _parseDouble(json['weight']),
      notes: json['notes'],
      recordedAt: DateTime.parse(json['recordedAt'] ?? DateTime.now().toIso8601String()).toLocal(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()).toLocal(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'bloodPressure': bloodPressure,
    'bloodGlucose': bloodGlucose,
    'heartRate': heartRate,
    'temperature': temperature,
    'weight': weight,
    'notes': notes,
    'recordedAt': recordedAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class Allergy {
  final String id;
  final String name;
  final String severity;

  Allergy({
    required this.id,
    required this.name,
    required this.severity,
  });

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      severity: json['severity'] ?? 'mild',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'severity': severity,
  };
}

class ChronicCondition {
  final String id;
  final String name;
  final String status;

  ChronicCondition({
    required this.id,
    required this.name,
    required this.status,
  });

  factory ChronicCondition.fromJson(Map<String, dynamic> json) {
    return ChronicCondition(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
  };
}

class PatientHealthInfo {
  final String id;
  final String? bloodGroup;
  final double? height;
  final double? weight;

  PatientHealthInfo({
    required this.id,
    this.bloodGroup,
    this.height,
    this.weight,
  });

  factory PatientHealthInfo.fromJson(Map<String, dynamic> json) {
    return PatientHealthInfo(
      id: json['id'] ?? '',
      bloodGroup: json['bloodGroup'],
      height: HealthData._parseDouble(json['height']),
      weight: HealthData._parseDouble(json['weight']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bloodGroup': bloodGroup,
    'height': height,
    'weight': weight,
  };
}

class HealthDataResponse {
  final PatientHealthInfo patient;
  final List<HealthData> healthData;
  final List<Allergy> allergies;
  final List<ChronicCondition> chronicConditions;

  HealthDataResponse({
    required this.patient,
    required this.healthData,
    required this.allergies,
    required this.chronicConditions,
  });

  factory HealthDataResponse.fromJson(Map<String, dynamic> json) {
    final patientJson = json['patient'] ?? {};
    final healthDataList = json['healthData'] ?? [];
    final allergiesList = json['allergies'] ?? [];
    final conditionsList = json['chronicConditions'] ?? [];

    return HealthDataResponse(
      patient: PatientHealthInfo.fromJson(patientJson),
      healthData: List<HealthData>.from(
        healthDataList.map((item) => HealthData.fromJson(item)),
      ),
      allergies: List<Allergy>.from(
        allergiesList.map((item) => Allergy.fromJson(item)),
      ),
      chronicConditions: List<ChronicCondition>.from(
        conditionsList.map((item) => ChronicCondition.fromJson(item)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'patient': patient.toJson(),
    'healthData': healthData.map((item) => item.toJson()).toList(),
    'allergies': allergies.map((item) => item.toJson()).toList(),
    'chronicConditions': chronicConditions.map((item) => item.toJson()).toList(),
  };
}
