import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  // ==================== Initialize ====================
  Future<void> init() async {
    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      _user = _authService.getSavedUser();
      // Try to refresh profile
      try {
        _user = await _authService.getProfile();
      } catch (_) {
        // Use cached data if network fails
      }
    }
    notifyListeners();
  }

  // ==================== Login ====================
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Register ====================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    int? age,
    String? gender,
    String? bloodGroup,
    double? height,
    double? weight,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        age: age,
        gender: gender,
        bloodGroup: bloodGroup,
        height: height,
        weight: weight,
      );
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Forgot Password ====================
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Logout ====================
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // ==================== Refresh Profile ====================
  Future<void> refreshProfile() async {
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  // ==================== Clear Error ====================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    // Extract actual error message from Dio response
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'No internet connection';
      }
      // Try to get server error message
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['message'] != null) {
          return responseData['message'];
        }
        if (responseData['details'] != null) {
          final details = responseData['details'];
          if (details is Map) {
            return details.values.first.toString();
          }
          return details.toString();
        }
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) return 'Email already registered';
      if (statusCode == 401) return 'Invalid email or password';
      if (statusCode == 400) return 'Please check your input and try again';
      return 'Server error ($statusCode). Please try again.';
    }
    String msg = e.toString();
    msg = msg.replaceAll('Exception: ', '');
    return msg;
  }
}
