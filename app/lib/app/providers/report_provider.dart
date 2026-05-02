import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../../core/services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<Report> _reports = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // ==================== Load Reports ====================
  Future<void> loadReports({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _offset = 0;
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    if (refresh) notifyListeners();

    try {
      final newReports = await _reportService.getReports(
        limit: _limit,
        offset: _offset,
      );

      if (refresh) {
        _reports = newReports;
      } else {
        _reports.addAll(newReports);
      }

      _hasMore = newReports.length >= _limit;
      _offset += newReports.length;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== Load More ====================
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await loadReports();
  }

  // ==================== Upload & Create Report ====================
  Future<bool> uploadReport({
    required String title,
    required String type,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
    String? documentDate,
    String privacy = 'private',
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Get signed upload URL
      final uploadData = await _reportService.getUploadUrl(
        fileName: fileName,
        contentType: contentType,
        folder: type == 'prescription' ? 'prescriptions' : 'reports',
      );

      final signedUrl = uploadData['signedUrl'];
      final path = uploadData['path'];

      // Step 2: Upload file to Supabase
      await ApiService().uploadToSignedUrl(
        signedUrl,
        fileBytes,
        fileName,
        contentType,
      );

      // Step 3: Finalize upload
      final report = await _reportService.finalizeUpload(
        path: path,
        type: type,
        title: title,
        documentDate: documentDate,
        privacy: privacy,
      );

      // Add to list
      _reports.insert(0, report);
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Delete Report ====================
  Future<bool> deleteReport(String reportId) async {
    try {
      await _reportService.deleteReport(reportId);
      _reports.removeWhere((r) => r.recordId == reportId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ==================== Get Report Detail ====================
  Future<Report?> getReportDetail(String reportId) async {
    try {
      return await _reportService.getReportDetail(reportId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
