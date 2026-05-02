import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== JWT Token ====================
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  // ==================== User Data ====================
  Future<void> saveUserId(String userId) async {
    await _prefs?.setString(AppConstants.userIdKey, userId);
  }

  String? getUserId() {
    return _prefs?.getString(AppConstants.userIdKey);
  }

  Future<void> savePatientId(String patientId) async {
    await _prefs?.setString(AppConstants.patientIdKey, patientId);
  }

  String? getPatientId() {
    return _prefs?.getString(AppConstants.patientIdKey);
  }

  Future<void> saveUserData(String jsonString) async {
    await _prefs?.setString(AppConstants.userDataKey, jsonString);
  }

  String? getUserData() {
    return _prefs?.getString(AppConstants.userDataKey);
  }

  // ==================== Onboarding ====================
  Future<void> setOnboardingComplete() async {
    await _prefs?.setBool(AppConstants.onboardingKey, true);
  }

  bool isOnboardingComplete() {
    return _prefs?.getBool(AppConstants.onboardingKey) ?? false;
  }

  // ==================== Clear All ====================
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }

  // ==================== Logged in check ====================
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
