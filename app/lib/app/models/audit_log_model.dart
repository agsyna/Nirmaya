class AuditLog {
  final String id;
  final String doctorName;
  final String action;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.doctorName,
    required this.action,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id']?.toString() ?? '',
      doctorName: json['doctorName'] ?? json['actorName'] ?? 'System',
      action: json['action'] ?? 'Unknown action',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}
