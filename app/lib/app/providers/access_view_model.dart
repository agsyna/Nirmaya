import 'package:flutter/material.dart';
import '../models/share_token_model.dart';
import '../services/share_token_service.dart';

class AccessViewModel extends ChangeNotifier {
  final ShareTokenService _shareTokenService = ShareTokenService();

  List<ShareToken> _shareTokens = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  String? _patientId;

  List<ShareToken> get shareTokens => _shareTokens;
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
}
