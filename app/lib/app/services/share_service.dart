import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/share_token_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShareService {
  final supabase = Supabase.instance.client;
  
  // Change this to your API URL
  static const String apiBaseUrl = 'https://your-api-url.com/api';

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
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call backend API
      final response = await http.post(
        Uri.parse('$apiBaseUrl/create-share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'expiry_time': expiryTime,
          'access_scope': accessScope,
          'max_access_count': maxAccessCount,
          'doctor_id': doctorId,
          'user_id': user.id,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create share token');
      }

      final data = jsonDecode(response.body);
      return ShareTokenResponse.fromJson(data);
    } catch (e) {
      throw Exception('Error creating share token: $e');
    }
  }

  /// Get all share tokens created by current user
  Future<List<ShareToken>> getMyShareTokens() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('share_tokens')
          .select()
          .eq('created_by', user.id);

      return (response as List)
          .map((token) => ShareToken.fromJson(token))
          .toList();
    } catch (e) {
      throw Exception('Error fetching share tokens: $e');
    }
  }

  /// Revoke a share token
  Future<void> revokeToken(String token) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/revoke-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'user_id': user.id,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to revoke token');
      }
    } catch (e) {
      throw Exception('Error revoking token: $e');
    }
  }

  /// Get access logs for a token
  Future<List<AccessLog>> getAccessLogs(String tokenId) async {
    try {
      final response = await supabase
          .from('access_logs')
          .select()
          .eq('token_id', tokenId)
          .order('accessed_at', ascending: false);

      return (response as List)
          .map((log) => AccessLog.fromJson(log))
          .toList();
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
      await supabase
          .from('share_tokens')
          .update({'max_access_count': newMaxCount})
          .eq('id', tokenId);
    } catch (e) {
      throw Exception('Error updating access count: $e');
    }
  }

  /// Get token details
  Future<ShareToken?> getTokenDetails(String tokenId) async {
    try {
      final response = await supabase
          .from('share_tokens')
          .select()
          .eq('id', tokenId)
          .single();

      return ShareToken.fromJson(response);
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
      token: json['token'],
      link: json['link'],
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
