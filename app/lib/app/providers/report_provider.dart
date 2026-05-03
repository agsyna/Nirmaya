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
  String _currentEndpoint = 'reports'; // 'reports' or 'prescriptions'

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String get currentEndpoint => _currentEndpoint;

  // ==================== Load Reports ====================
  Future<void> loadReports({
    bool refresh = false,
    String endpoint = 'reports',
  }) async {
    if (_isLoading) return;

    // If endpoint changed, reset pagination
    if (endpoint != _currentEndpoint) {
      _currentEndpoint = endpoint;
      _offset = 0;
      _hasMore = true;
      refresh = true;
    }

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
        endpoint: _currentEndpoint,
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
      // Step 1: Upload file directly to backend (multipart form data)
      debugPrint('Uploading file: $fileName');
      final uploadData = await _reportService.uploadFileBytes(
        fileBytes: fileBytes,
        fileName: fileName,
        folder: type == 'prescription' ? 'prescriptions' : 'reports',
      );

      final path = uploadData['path'];
      debugPrint('File uploaded, path: $path');

      // Step 2: Finalize upload with metadata
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
