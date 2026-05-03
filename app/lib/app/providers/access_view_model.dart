import 'package:flutter/material.dart';
import '../models/share_token_model.dart';
import '../services/share_token_service.dart';
import '../services/access_request_service.dart';

class AccessViewModel extends ChangeNotifier {
  final ShareTokenService _shareTokenService = ShareTokenService();
  final AccessRequestService _accessRequestService = AccessRequestService();

  List<ShareToken> _shareTokens = [];
  List<dynamic> _accessRequests = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _patientId;

  List<ShareToken> get shareTokens => _shareTokens;
  List<dynamic> get accessRequests => _accessRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // ==================== Load Share Tokens ====================
  Future<void> loadShareTokens({
    bool refresh = false,
    String? patientId,
  }) async {
    if (_isLoading) return;

    if (patientId != null) {
      _patientId = patientId;
    }

    if (refresh) {
      _offset = 0;
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    if (refresh) notifyListeners();

    try {
      final newTokens = await _shareTokenService.getShareTokens(
        limit: _limit,
        offset: _offset,
      );

      if (refresh) {
        _shareTokens = newTokens;
      } else {
        _shareTokens.addAll(newTokens);
      }

      _hasMore = newTokens.length >= _limit;
      _offset += newTokens.length;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== Load More ====================
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await loadShareTokens();
  }

  // ==================== Create Share Token ====================
  Future<bool> createShareToken({
    required List<String> scope,
    String expiryTime = '7 days',
    String accessLevel = 'doctor',
    int? maxAccessCount,
  }) async {
    _errorMessage = null;

    try {
      if (_patientId == null) {
        throw Exception('Patient ID not set');
      }

      final token = await _shareTokenService.createShareToken(
        patientId: _patientId!,
        scope: scope,
        expiryTime: expiryTime,
        accessLevel: accessLevel,
        maxAccessCount: maxAccessCount,
      );

      _shareTokens.insert(0, token);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Revoke Share Token ====================
  Future<bool> revokeShareToken(String tokenId) async {
    _errorMessage = null;

    try {
      await _shareTokenService.revokeShareToken(tokenId);
      _shareTokens.removeWhere((token) => token.id == tokenId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Update Share Token Scope ====================
  Future<bool> updateShareTokenScope({
    required String tokenId,
    required List<String> newScope,
  }) async {
    _errorMessage = null;

    try {
      final updatedToken = await _shareTokenService.updateShareTokenScope(
        tokenId: tokenId,
        scope: newScope,
      );

      final index = _shareTokens.indexWhere((token) => token.id == tokenId);
      if (index != -1) {
        _shareTokens[index] = updatedToken;
      } else {
        _shareTokens.insert(0, updatedToken);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Get Doctor Access Requests ====================
  Future<void> loadAccessRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accessRequests = await _accessRequestService.getAccessRequests();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== Approve Access Request ====================
  Future<bool> approveAccessRequest({
    required String requestId,
    required List<String> scope,
    required int expiresInMinutes,
  }) async {
    _errorMessage = null;

    try {
      final data = await _accessRequestService.approveRequest(requestId, scope, expiresInMinutes);
      // Update local state
      final index = _accessRequests.indexWhere((req) => req['requestId'] == requestId);
      if (index != -1) {
        _accessRequests[index] = {
          ..._accessRequests[index],
          'status': 'approved',
          'approvedScope': data['approvedScope'],
          'expiresAt': data['expiresAt'],
          'shareTokenId': data['shareTokenId'],
        };
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Reject Access Request ====================
  Future<bool> rejectAccessRequest(String requestId) async {
    _errorMessage = null;

    try {
      await _accessRequestService.rejectRequest(requestId);
      final index = _accessRequests.indexWhere((req) => req['requestId'] == requestId);
      if (index != -1) {
        _accessRequests[index] = {
          ..._accessRequests[index],
          'status': 'rejected',
        };
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Update Access Request ====================
  Future<bool> updateAccessRequest({
    required String requestId,
    required List<String> scope,
    required int expiresInMinutes,
  }) async {
    _errorMessage = null;

    try {
      final data = await _accessRequestService.updateRequest(requestId, scope, expiresInMinutes);
      final index = _accessRequests.indexWhere((req) => req['requestId'] == requestId);
      if (index != -1) {
        _accessRequests[index] = {
          ..._accessRequests[index],
          'approvedScope': data['approvedScope'],
          'expiresAt': data['expiresAt'],
          'shareTokenId': data['shareTokenId'],
        };
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Revoke Access Request ====================
  Future<bool> revokeAccessRequest(String requestId) async {
    _errorMessage = null;

    try {
      await _accessRequestService.revokeRequest(requestId);
      final index = _accessRequests.indexWhere((req) => req['requestId'] == requestId);
      if (index != -1) {
        _accessRequests[index] = {
          ..._accessRequests[index],
          'status': 'revoked',
        };
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
