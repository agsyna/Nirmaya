import 'package:flutter/material.dart';
import '../models/emergency_model.dart';
import '../services/emergency_service.dart';

class EmergencyViewModel extends ChangeNotifier {
  final EmergencyService _emergencyService = EmergencyService();

  Emergency? _currentEmergency;
  List<Emergency> _emergencyHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;

  Emergency? get currentEmergency => _currentEmergency;
  List<Emergency> get emergencyHistory => _emergencyHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // ==================== Trigger Emergency SOS ====================
  Future<bool> triggerEmergencySos({
    required String affectedPatientId,
    required String latitude,
    required String longitude,
    required List<String> serviceTypes,
    required String description,
  }) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final emergency = await _emergencyService.triggerEmergencySos(
        affectedPatientId: affectedPatientId,
        latitude: latitude,
        longitude: longitude,
        serviceTypes: serviceTypes,
        description: description,
      );

      _currentEmergency = emergency;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Load Emergency History ====================
  Future<void> loadEmergencyHistory({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      _offset = 0;
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    if (refresh) notifyListeners();

    try {
      final history = await _emergencyService.getEmergencyHistory(
        limit: _limit,
        offset: _offset,
      );

      if (refresh) {
        _emergencyHistory = history;
      } else {
        _emergencyHistory.addAll(history);
      }

      _hasMore = history.length >= _limit;
      _offset += history.length;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== Load More History ====================
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await loadEmergencyHistory();
  }

  // ==================== Get Emergency Detail ====================
  Future<Emergency?> getEmergencyDetail(String sosId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final emergency = await _emergencyService.getEmergencyDetail(sosId);
      debugPrint('Loaded emergency detail: ${emergency.sosId}, status: ${emergency.status}');
      _currentEmergency = emergency;
      _isLoading = false;
      notifyListeners();
      return emergency;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ==================== Resolve Emergency ====================
  Future<bool> resolveEmergency(String sosId) async {
    _errorMessage = null;

    try {
      final emergency = await _emergencyService.resolveEmergency(sosId);
      _currentEmergency = emergency;
      
      // Update in history list
      final index = _emergencyHistory.indexWhere((e) => e.sosId == sosId);
      if (index != -1) {
        _emergencyHistory[index] = emergency;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Clear Current Emergency ====================
  void clearCurrentEmergency() {
    _currentEmergency = null;
    _errorMessage = null;
    notifyListeners();
  }
}
