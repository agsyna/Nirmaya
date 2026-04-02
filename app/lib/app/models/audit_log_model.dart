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
}
