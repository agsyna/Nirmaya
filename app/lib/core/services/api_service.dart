import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService().getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  late final Dio _dio;
  Dio get dio => _dio;

  // ==================== GET ====================
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // ==================== POST ====================
  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    debugPrint('POST Request to $path with data: $data');
    debugPrint('Full URL: ${_dio.options.baseUrl}$path');
    debugPrint('data type: ${data.runtimeType}');
    debugPrint('data content: $data');
    return await _dio.post(path, data: data);
  }

  // ==================== PUT ====================
  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    return await _dio.put(path, data: data);
  }

  // ==================== DELETE ====================
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // ==================== Upload to signed URL ====================
  Future<Response> uploadToSignedUrl(
    String signedUrl,
    List<int> fileBytes,
    String fileName,
    String contentType,
  ) async {
    final uploadDio = Dio();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    return await uploadDio.post(
      signedUrl,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
  }
}
