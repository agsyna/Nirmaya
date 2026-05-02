import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/audit_log_model.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();

  User? _currentUser;
  List<AuditLog> _auditLogs = [];
  bool _isLoading = false;

  HomeViewModel() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = _authService.getSavedUser();
    
    // Fetch real audit logs
    _auditLogs = await _patientService.getAuditLogs();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _auditLogs = await _patientService.getAuditLogs();
    _currentUser = _authService.getSavedUser();
    notifyListeners();
  }

  Future<bool> triggerEmergency() async {
    return await _patientService.triggerEmergency();
  }

  User get user => _currentUser ?? User(
    id: 'unknown',
    name: 'Guest',
    age: 0,
    gender: 'Unknown',
    profileImageUrl: '',
  );
  
  List<AuditLog> get logs => _auditLogs;
  bool get isLoading => _isLoading;
}
