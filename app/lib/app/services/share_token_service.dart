import 'package:flutter/cupertino.dart';

import '../../core/services/api_service.dart';
import '../models/share_token_model.dart';

class ShareTokenService {
  final ApiService _api = ApiService();

  // ==================== Get All Share Tokens ====================
  Future<List<ShareToken>> getShareTokens({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        '/patient/share-tokens',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        final List list = data['data'] ?? [];
        return list.map((e) => ShareToken.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load share tokens');
      }
    } catch (e) {
      debugPrint('Error in getShareTokens: $e');
      rethrow;
    }
  }

  // ==================== Create Share Token ====================
  Future<ShareToken> createShareToken({
    required String patientId,
    required List<String> scope,
    String expiryTime = '7 days',
    String accessLevel = 'doctor',
    int? maxAccessCount,
  }) async {
    try {
      final body = {
        'patientId': patientId,
        'scope': scope,
        'expiryTime': expiryTime,
        'accessLevel': accessLevel,
      };
      if (maxAccessCount != null) body['maxAccessCount'] = maxAccessCount;

      final response = await _api.post(
        '/patient/share-tokens',
        data: body,
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return ShareToken.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create share token');
      }
    } catch (e) {
      debugPrint('Error in createShareToken: $e');
      rethrow;
    }
  }

  // ==================== Revoke Share Token ====================
  Future<void> revokeShareToken(String tokenId) async {
    try {
      final response = await _api.delete('/patient/share-tokens/$tokenId');
      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(
          data['message'] ?? 'Failed to revoke share token',
        );
      }
    } catch (e) {
      debugPrint('Error in revokeShareToken: $e');
      rethrow;
    }
  }

  // ==================== Update Share Token Scope ====================
  Future<ShareToken> updateShareTokenScope({
    required String tokenId,
    required List<String> scope,
  }) async {
    try {
      // Delete old token and create new one with updated scope
      await revokeShareToken(tokenId);
      
      // Get the original token details from the list to recreate with new scope
      final tokens = await getShareTokens();
      final originalToken = tokens.firstWhere(
        (t) => t.id == tokenId,
        orElse: () => throw Exception('Token not found'),
      );

      return await createShareToken(
        patientId: originalToken.patientId,
        scope: scope,
        accessLevel: originalToken.accessLevel,
      );
    } catch (e) {
      debugPrint('Error in updateShareTokenScope: $e');
      rethrow;
    }
  }
}
