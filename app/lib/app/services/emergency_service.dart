import 'package:flutter/cupertino.dart';
import '../../core/services/api_service.dart';
import '../models/emergency_model.dart';

class EmergencyService {
  final ApiService _api = ApiService();

  // ==================== Trigger Emergency SOS ====================
  Future<Emergency> triggerEmergencySos({
    required String affectedPatientId,
    required String latitude,
    required String longitude,
    required List<String> serviceTypes,
    required String description,
  }) async {
    try {
      final body = {
        'affectedPatientId': affectedPatientId,
        'latitude': latitude,
        'longitude': longitude,
        'serviceTypes': serviceTypes, // The backend expects 'serviceType' according to the 400 error
        'description': description,
      };

      final response = await _api.post(
        '/patient/emergency',
        data: body,
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return Emergency.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to trigger emergency SOS');
      }
    } catch (e) {
      debugPrint('Error in triggerEmergencySos: $e');
      rethrow;
    }
  }

  // ==================== Get Emergency History ====================
  Future<List<Emergency>> getEmergencyHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        '/patient/emergency',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        final List list = data['data'] ?? [];
        return list.map((e) => Emergency.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load emergency history');
      }
    } catch (e) {
      debugPrint('Error in getEmergencyHistory: $e');
      rethrow;
    }
  }

  // ==================== Get Emergency Detail ====================
  Future<Emergency> getEmergencyDetail(String sosId) async {
    try {
      final response = await _api.get('/patient/emergency/$sosId');

      final data = response.data;
      if (data['status'] == 'success') {
        return Emergency.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load emergency detail');
      }
    } catch (e) {
      debugPrint('Error in getEmergencyDetail: $e');
      rethrow;
    }
  }

  // ==================== Resolve Emergency ====================
  Future<Emergency> resolveEmergency(String sosId) async {
    try {
      final body = {'status': 'resolved'};

      final response = await _api.put(
        '/patient/emergency/$sosId',
        data: body,
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return Emergency.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to resolve emergency');
      }
    } catch (e) {
      debugPrint('Error in resolveEmergency: $e');
      rethrow;
    }
  }
}
