class ShareToken {
  final String id;
  final String token;
  final String patientId;
  final String? doctorId;
  final List<String> accessScope;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int maxAccessCount;
  final int accessCount;
  final DateTime? lastAccessedAt;
  final bool revoked;
  final String status;
  final String? createdBy;

  ShareToken({
    required this.id,
    required this.token,
    required this.patientId,
    this.doctorId,
    required this.accessScope,
    required this.expiresAt,
    required this.createdAt,
    required this.maxAccessCount,
    required this.accessCount,
    this.lastAccessedAt,
    required this.revoked,
    required this.status,
    this.createdBy,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isLimitExceeded => accessCount >= maxAccessCount;
  int get accessRemaining => (maxAccessCount - accessCount).clamp(0, maxAccessCount);
  bool get isValid => !revoked && !isExpired && !isLimitExceeded && status == 'active';

  factory ShareToken.fromJson(Map<String, dynamic> json) {
    return ShareToken(
      id: json['id'],
      token: json['token'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      accessScope: List<String>.from(json['access_scope'] ?? []),
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      maxAccessCount: json['max_access_count'] ?? 5,
      accessCount: json['access_count'] ?? 0,
      lastAccessedAt: json['last_accessed_at'] != null 
          ? DateTime.parse(json['last_accessed_at']) 
          : null,
      revoked: json['revoked'] ?? false,
      status: json['status'] ?? 'active',
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'token': token,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'access_scope': accessScope,
    'expires_at': expiresAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'max_access_count': maxAccessCount,
    'access_count': accessCount,
    'last_accessed_at': lastAccessedAt?.toIso8601String(),
    'revoked': revoked,
    'status': status,
    'created_by': createdBy,
  };
}

class AccessLog {
  final String id;
  final String tokenId;
  final DateTime accessedAt;
  final String? ipAddress;
  final String? userAgent;

  AccessLog({
    required this.id,
    required this.tokenId,
    required this.accessedAt,
    this.ipAddress,
    this.userAgent,
  });

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id'],
      tokenId: json['token_id'],
      accessedAt: DateTime.parse(json['accessed_at']),
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
    );
  }
}
