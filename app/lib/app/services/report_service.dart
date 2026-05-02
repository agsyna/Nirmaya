import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

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

  // ==================== Upload File (from File) ====================
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    String folder = 'reports',
  }) async {
    try {
      final fileName = file.path.split('/').last;
      debugPrint('Uploading file: $fileName to folder: $folder');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'folder': folder,
      });

      final response = await _api.post(
        '/patient/uploads/file',
        data: formData,
      );

      final data = response.data;
      if (data['status'] == 'success') {
        debugPrint('File uploaded successfully: ${data['data']}');
        return data['data'];
      } else {
        debugPrint('Failed to upload file: ${data['message']}');
        throw Exception(data['message'] ?? 'Failed to upload file');
      }
    } catch (e) {
      debugPrint('Error in uploadFile: $e');
      rethrow;
    }
  }

  // ==================== Upload File (from bytes) ====================
  Future<Map<String, dynamic>> uploadFileBytes({
    required List<int> fileBytes,
    required String fileName,
    String folder = 'reports',
  }) async {
    try {
      debugPrint('Uploading file from bytes: $fileName to folder: $folder');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
        'folder': folder,
      });

      final response = await _api.post(
        '/patient/uploads/file',
        data: formData,
      );

      final data = response.data;
      if (data['status'] == 'success') {
        debugPrint('File uploaded successfully: ${data['data']}');
        return data['data'];
      } else {
        debugPrint('Failed to upload file: ${data['message']}');
        throw Exception(data['message'] ?? 'Failed to upload file');
      }
    } catch (e) {
      debugPrint('Error in uploadFileBytes: $e');
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
      debugPrint('Error in finalizeUpload: $e');
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
