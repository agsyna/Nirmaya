import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/health_data_model.dart';
import '../services/patient_service.dart';

class PatientProfileProvider extends ChangeNotifier {
  final PatientService _patientService = PatientService();

  User? _profile;
  HealthDataResponse? _healthData;
  bool _isLoading = false;
  String? _errorMessage;

  User? get profile => _profile;
  HealthDataResponse? get healthData => _healthData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _patientService.getProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHealthData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _healthData = await _patientService.getHealthData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await fetchProfile();
      await fetchHealthData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitHealthData({
    String? bloodPressure,
    int? bloodGlucose,
    int? heartRate,
    double? temperature,
    double? weight,
    String? notes,
    DateTime? recordedAt,
  }) async {
    try {
      await _patientService.submitHealthData(
        bloodPressure: bloodPressure,
        bloodGlucose: bloodGlucose,
        heartRate: heartRate,
        temperature: temperature,
        weight: weight,
        notes: notes,
        recordedAt: recordedAt,
      );
      // Refresh health data after submission
      await fetchHealthData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
