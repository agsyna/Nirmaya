import '../../core/services/api_service.dart';
import '../models/share_token_model.dart';

class ShareService {
  final ApiService _api = ApiService();

  /// Create a shareable link
  /// Returns: ShareTokenResponse with link, token, and expiry
  Future<ShareTokenResponse> createShareToken({
    required String patientId,
    required String expiryTime,
    required List<String> accessScope,
    required int maxAccessCount,
    String? doctorId,
  }) async {
    try {
      final response = await _api.post(
        '/patient/share-tokens',
        data: {
          'patientId': patientId,
          'expiryTime': expiryTime,
          'accessScope': accessScope,
          'maxAccessCount': maxAccessCount,
          if (doctorId != null) 'doctorId': doctorId,
        },
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return ShareTokenResponse.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create share token');
      }
    } catch (e) {
      throw Exception('Error creating share token: $e');
    }
  }

  /// Get all share tokens created by current user
  Future<List<ShareToken>> getMyShareTokens() async {
    try {
      final response = await _api.get('/patient/share-tokens');
      final data = response.data;
      
      if (data['status'] == 'success') {
        final List list = data['data'] ?? [];
        return list.map((token) => ShareToken.fromJson(token)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch share tokens');
      }
    } catch (e) {
      throw Exception('Error fetching share tokens: $e');
    }
  }

  /// Revoke a share token
  Future<void> revokeToken(String token) async {
    try {
      final response = await _api.delete('/patient/share-tokens/$token');
      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to revoke token');
      }
    } catch (e) {
      throw Exception('Error revoking token: $e');
    }
  }

  /// Get access logs for a token
  Future<List<AccessLog>> getAccessLogs(String tokenId) async {
    try {
      final response = await _api.get(
        '/patient/access-logs',
        queryParameters: {'tokenId': tokenId},
      );
      final data = response.data;

      if (data['status'] == 'success') {
        final List list = data['data'] ?? [];
        return list.map((log) => AccessLog.fromJson(log)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch access logs');
      }
    } catch (e) {
      throw Exception('Error fetching access logs: $e');
    }
  }

  /// Update max access count for a token
  Future<void> updateMaxAccessCount(
    String tokenId,
    int newMaxCount,
  ) async {
    try {
      // Assuming PUT /patient/share-tokens/:tokenId or similar if available
      final response = await _api.put(
        '/patient/share-tokens/$tokenId',
        data: {'maxAccessCount': newMaxCount},
      );
      final data = response.data;
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to update access count');
      }
    } catch (e) {
      throw Exception('Error updating access count: $e');
    }
  }

  /// Get token details
  Future<ShareToken?> getTokenDetails(String tokenId) async {
    try {
      // Depending on API, maybe GET /patient/share-tokens/:tokenId doesn't exist but we can fetch all and filter
      final tokens = await getMyShareTokens();
      return tokens.firstWhere((t) => t.id == tokenId);
    } catch (e) {
      return null;
    }
  }
}

/// Response model for create-share API
class ShareTokenResponse {
  final String token;
  final String link;
  final DateTime expiresAt;
  final DateTime createdAt;

  ShareTokenResponse({
    required this.token,
    required this.link,
    required this.expiresAt,
    required this.createdAt,
  });

  factory ShareTokenResponse.fromJson(Map<String, dynamic> json) {
    return ShareTokenResponse(
      token: json['token'] ?? '',
      link: json['link'] ?? '',
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
