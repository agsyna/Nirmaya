import '../../core/services/api_service.dart';
import '../models/report_model.dart';

class ReportService {
  final ApiService _api = ApiService();

  // ==================== Get All Reports ====================
  Future<List<Report>> getReports({int limit = 10, int offset = 0}) async {
    try {
      final response = await _api.get(
        '/patient/reports',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        final List list = data['data'] ?? [];
        return list.map((e) => Report.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load reports');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Get Report Detail ====================
  Future<Report> getReportDetail(String reportId) async {
    try {
      final response = await _api.get(
        '/patient/reports',
        queryParameters: {'reportId': reportId},
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return Report.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load report');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Get Upload URL ====================
  Future<Map<String, dynamic>> getUploadUrl({
    required String fileName,
    required String contentType,
    String folder = 'reports',
  }) async {
    try {
      final response = await _api.post(
        '/patient/upload-url',
        data: {
          'fileName': fileName,
          'contentType': contentType,
          'folder': folder,
        },
      );

      final data = response.data;
      if (data['status'] == 'success') {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get upload URL');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Finalize Upload ====================
  Future<Report> finalizeUpload({
    required String path,
    required String type,
    required String title,
    String? originalContent,
    String? documentDate,
    String privacy = 'private',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{
        'path': path,
        'type': type,
        'title': title,
        'privacy': privacy,
      };
      if (originalContent != null) body['originalContent'] = originalContent;
      if (documentDate != null) body['documentDate'] = documentDate;
      if (metadata != null) body['metadata'] = metadata;

      final response = await _api.post('/patient/finalize-upload', data: body);
      final data = response.data;

      if (data['status'] == 'success') {
        return Report.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to finalize upload');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Create Report (without file) ====================
  Future<Report> createReport({
    required String type,
    required String title,
    required String fileUrl,
    String? originalContent,
    String? documentDate,
    String privacy = 'private',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
        'title': title,
        'fileUrl': fileUrl,
        'privacy': privacy,
      };
      if (originalContent != null) body['originalContent'] = originalContent;
      if (documentDate != null) body['documentDate'] = documentDate;
      if (metadata != null) body['metadata'] = metadata;

      final response = await _api.post('/patient/reports', data: body);
      final data = response.data;

      if (data['status'] == 'success') {
        return Report.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create report');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Delete Report ====================
  Future<void> deleteReport(String reportId) async {
    try {
      final response = await _api.delete('/patient/reports/$reportId');
      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to delete report');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Update Report ====================
  Future<void> updateReport(
    String reportId, {
    String? title,
    String? privacy,
    String? aiSummary,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (privacy != null) body['privacy'] = privacy;
      if (aiSummary != null) body['aiSummary'] = aiSummary;
      if (metadata != null) body['metadata'] = metadata;

      final response = await _api.put(
        '/patient/reports/$reportId',
        data: body,
      );
      final data = response.data;

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to update report');
      }
    } catch (e) {
      rethrow;
    }
  }
}
