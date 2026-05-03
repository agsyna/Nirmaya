import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  late final Dio _dio;

  AIService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.aiBaseUrl,
      connectTimeout: const Duration(minutes: 5), // AI can take time
      receiveTimeout: const Duration(minutes: 5),
    ));

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  // ==================== Analyze Report ====================
  Future<Map<String, dynamic>> analyzeReport({
    required List<int> fileBytes,
    required String fileName,
    required String patientId,
    required String reportType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        'patient_id': patientId,
        'report_type': reportType,
      });

      final response = await _dio.post('/analyze', data: formData);
      
      debugPrint('====================================');
      debugPrint('🤖 AI /analyze RESPONSE RECEIVED:');
      debugPrint(response.data.toString());
      debugPrint('====================================');
      
      return response.data; // This has status, summary, extracted_data, report_id
    } catch (e) {
      debugPrint('❌ AI Analysis Error: $e');
      throw Exception('Failed to analyze report with AI: $e');
    }
  }

  // ==================== Chat With Report ====================
  Future<String> chatWithReport(String aiReportId, String question) async {
    try {
      final formData = FormData.fromMap({
        'report_id': aiReportId,
        'question': question,
      });

      final response = await _dio.post('/chat', data: formData);
      return response.data['answer'] ?? 'I could not generate an answer.';
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      throw Exception('Failed to chat with report: $e');
    }
  }
}
