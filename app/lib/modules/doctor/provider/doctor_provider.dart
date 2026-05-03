import 'package:flutter/material.dart';
import '../services/doctor_api.dart';

class DoctorProvider extends ChangeNotifier {
  final DoctorApi _doctorApi = DoctorApi();

  List<dynamic> _accessRequests = [];
  bool _isLoading = false;
  bool _isFetchingData = false;
  Map<String, dynamic>? _patientData;
  String? _errorMessage;

  List<dynamic> get accessRequests => _accessRequests;
  bool get isLoading => _isLoading;
  bool get isFetchingData => _isFetchingData;
  Map<String, dynamic>? get patientData => _patientData;
  String? get errorMessage => _errorMessage;

  // Fetch access requests
  Future<void> fetchRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accessRequests = await _doctorApi.getAccessRequests();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send access request
  Future<bool> sendAccessRequest(String patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRequest = await _doctorApi.createAccessRequest(patientId);
      _accessRequests.insert(0, newRequest);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch patient data using token
  Future<bool> fetchPatientData(String token) async {
    _isFetchingData = true;
    _errorMessage = null;
    _patientData = null; // Clear previous data
    notifyListeners();

    try {
      _patientData = await _doctorApi.getPatientData(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isFetchingData = false;
      notifyListeners();
    }
  }

  // Clear patient data when leaving the screen
  void clearPatientData() {
    _patientData = null;
    notifyListeners();
  }

  // Realtime update helper
  void updateRequest(Map<String, dynamic> updatedRequest) {
    final index = _accessRequests.indexWhere((r) => r['id'] == updatedRequest['id'] || r['requestId'] == updatedRequest['id']);
    if (index != -1) {
      _accessRequests[index] = updatedRequest;
      notifyListeners();
    } else {
      fetchRequests(); // If not found, just fetch all again
    }
  }
}
