import '../../core/services/api_service.dart';
import '../models/audit_log_model.dart';

class PatientService {
  final ApiService _api = ApiService();
  hjnkj

  Future<List<AuditLog>> getAuditLogs() async {
    try {
      final response = await _api.get('/patient/audit-logs');
      final data = response.data;
      if (data['status'] == 'success') {
        final List<dynamic> logsJson = data['data'];
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
}
