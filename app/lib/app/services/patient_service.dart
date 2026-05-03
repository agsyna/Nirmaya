import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../models/audit_log_model.dart';
import '../models/nominee_model.dart';

class PatientService {
  final ApiService _api = ApiService();

  Future<List<AuditLog>> getAuditLogs() async {
    try {
      final response = await _api.get('/patient/audit-logs');
      final data = response.data;
      if (data['status'] == 'success') {
        final List<dynamic> logsJson = data['data'];
        debugPrint("SYNA FIXED IT : $logsJson");
        return logsJson.map((json) => AuditLog.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load audit logs');
      }
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  Future<bool> triggerEmergency() async {
    try {
      final response = await _api.post('/patient/emergency', data: {});
      final data = response.data;
      return data['status'] == 'success';
    } catch (e) {
      print('Error triggering emergency: $e');
      return false;
    }
  }

  // ==================== Nominees ====================

  Future<List<Nominee>> getNominees() async {
    final response = await _api.get('/patient/nominees');
    final data = response.data;
    if (data['status'] == 'success') {
      final List<dynamic> list = data['data'] ?? [];
      return list.map((json) => Nominee.fromJson(json)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch nominees');
  }

  Future<Nominee> createNominee({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await _api.post(
      '/patient/nominees',
      data: {'name': name, 'email': email, 'phone': phone},
    );
    final data = response.data;
    if (data['status'] == 'success') {
      debugPrint('Created nominee: ${data['data']}');
      return Nominee.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create nominee');
  }

  Future<Nominee> updateNominee({
    required String id,
    String? name,
    String? email,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    final response = await _api.put('/patient/nominees/$id', data: body);
    final data = response.data;
    if (data['status'] == 'success') {
      return Nominee.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to update nominee');
  }
}
