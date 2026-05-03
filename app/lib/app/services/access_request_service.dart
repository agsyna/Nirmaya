import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';

class AccessRequestService {
  final ApiService _api = ApiService();

  // Get all access requests
  Future<List<dynamic>> getAccessRequests() async {
    try {
      final response = await _api.get('/patient/access-requests');
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch access requests');
      }
      throw Exception('Failed to fetch access requests');
    }
  }

  // Approve access request
  Future<Map<String, dynamic>> approveRequest(String requestId, List<String> scope, int expiresInMinutes) async {
    try {
      final response = await _api.post(
        '/patient/access-requests/$requestId/approve',
        data: {
          'scope': scope,
          'expiresInMinutes': expiresInMinutes,
        },
      );
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to approve request');
      }
      throw Exception('Failed to approve request');
    }
  }

  // Reject access request
  Future<void> rejectRequest(String requestId) async {
    try {
      await _api.post('/patient/access-requests/$requestId/reject');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to reject request');
      }
      throw Exception('Failed to reject request');
    }
  }

  // Update access request
  Future<Map<String, dynamic>> updateRequest(String requestId, List<String> scope, int expiresInMinutes) async {
    try {
      final response = await _api.post(
        '/patient/access-requests/$requestId/update',
        data: {
          'scope': scope,
          'expiresInMinutes': expiresInMinutes,
        },
      );
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update request');
      }
      throw Exception('Failed to update request');
    }
  }

  // Revoke access request
  Future<void> revokeRequest(String requestId) async {
    try {
      await _api.post('/patient/access-requests/$requestId/revoke');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to revoke request');
      }
      throw Exception('Failed to revoke request');
    }
  }
}
