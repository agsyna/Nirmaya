import 'dart:convert';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // ==================== Login ====================
  Future<User> login(String email, String password) async {
    try {
      final response = await _api.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      final isSuccess = data['status'] == 'success' || response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess) {
        final payload = data['data'] ?? data;
        if (payload['token'] == null) {
          throw Exception('Login failed: Token not found');
        }
        
        final user = User.fromLoginJson(payload);
        final token = payload['token'];

        // Save token and user data
        await _storage.saveToken(token);
        await _storage.saveUserId(user.id);
        if (user.patientId != null) {
          await _storage.savePatientId(user.patientId!);
        }
        await _storage.saveUserData(jsonEncode(user.toJson()));

        return user;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception('Invalid email or password');
      }
      rethrow;
    }
  }

  // ==================== Register ====================
  Future<User> register({
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
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      };

      if (phone != null) body['phone'] = phone;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;
      if (bloodGroup != null) body['bloodGroup'] = bloodGroup;
      if (height != null) body['height'] = height;
      if (weight != null) body['weight'] = weight;

      final response = await _api.post(
        '/auth/register/patient',
        data: body,
      );

      final data = response.data;
      final isSuccess = data['status'] == 'success' || response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess) {
        final payload = data['data'] ?? data;
        if (payload['token'] == null) {
          throw Exception('Registration failed: Token not found');
        }

        final user = User.fromLoginJson(payload);
        final token = payload['token'];

        await _storage.saveToken(token);
        await _storage.saveUserId(user.id);
        if (user.patientId != null) {
          await _storage.savePatientId(user.patientId!);
        }
        await _storage.saveUserData(jsonEncode(user.toJson()));

        return user;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e.toString().contains('409')) {
        throw Exception('Email already registered');
      }
      rethrow;
    }
  }

  // ==================== Forgot Password ====================
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _api.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return data['data']['message'] ?? 'Reset link sent to your email';
      } else {
        throw Exception(data['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Reset Password ====================
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _api.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'password': newPassword,
        },
      );

      final data = response.data;
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Get Profile ====================
  Future<User> getProfile() async {
    try {
      final response = await _api.get('/patient/me');
      final data = response.data;

      if (data['status'] == 'success') {
        return User.fromProfileJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Logout ====================
  Future<void> logout() async {
    await _storage.clearAll();
  }

  // ==================== Check Auth State ====================
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  // ==================== Get Saved User ====================
  User? getSavedUser() {
    final jsonStr = _storage.getUserData();
    if (jsonStr == null) return null;
    try {
      return User.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }
}
