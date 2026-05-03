import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';

class DoctorApi {
  final ApiService _apiService = ApiService();

  // 1. Create Access Request
  Future<Map<String, dynamic>> createAccessRequest(String patientId) async {
    try {
      final response = await _apiService.post(
        '/doctor/access-request',
        data: {'patientId': patientId},
      );
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to create access request');
      }
      throw Exception('Failed to create access request');
    }
  }

  // 2. Get Doctor Access Requests
  Future<List<dynamic>> getAccessRequests() async {
    try {
      final response = await _apiService.get('/doctor/access-requests');
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch access requests');
      }
      throw Exception('Failed to fetch access requests');
    }
  }

  // 3. Access Patient Data
  Future<Map<String, dynamic>> getPatientData(String token) async {
    try {
      final response = await _apiService.post('/share/$token/access');
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Access expired or invalid token');
      }
      throw Exception('Access expired or invalid token');
    }
  }
}
