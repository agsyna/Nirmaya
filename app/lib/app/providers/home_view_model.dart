import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/audit_log_model.dart';

class HomeViewModel extends ChangeNotifier {
  late User currentUser;
  late List<AuditLog> auditLogs;

  HomeViewModel() {
    _initializeData();
  }

  void _initializeData() {
    // Hardcoded demo data
    currentUser = User(
      id: '3356833915',
      name: 'Disha Satija',
      age: 20,
      gender: 'Female',
      profileImageUrl: 'https://via.placeholder.com/60',
    );

    auditLogs = [
      AuditLog(
        id: '1',
        doctorName: 'Mr. Sharma',
        action: 'accessed your reports',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AuditLog(
        id: '2',
        doctorName: 'Mr. Sharma',
        action: 'accessed your reports',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AuditLog(
        id: '3',
        doctorName: 'Mr. Sharma',
        action: 'accessed your reports',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AuditLog(
        id: '4',
        doctorName: 'Mr. Sharma',
        action: 'accessed your reports',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }

  User get user => currentUser;
  List<AuditLog> get logs => auditLogs;
}
