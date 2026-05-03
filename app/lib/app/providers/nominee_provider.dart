import 'package:flutter/material.dart';
import '../models/nominee_model.dart';
import '../services/patient_service.dart';

class NomineeProvider extends ChangeNotifier {
  final PatientService _service = PatientService();

  List<Nominee> _nominees = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Nominee> get nominees => List.unmodifiable(_nominees);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get count => _nominees.length;

  // ==================== Load ====================
  Future<void> loadNominees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _nominees = await _service.getNominees();
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Create ====================
  Future<bool> addNominee({required String name, required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nominee = await _service.createNominee(name: name, email: email);
      _nominees = [..._nominees, nominee];
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

  // ==================== Update ====================
  Future<bool> editNominee({
    required String id,
    required String name,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateNominee(
        id: id,
        name: name,
        email: email,
      );
      _nominees = _nominees.map((n) => n.id == id ? updated : n).toList();
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

  // ==================== Helper ====================
  String _parseError(Object e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('401')) return 'Unauthorised. Please log in again.';
    if (msg.contains('403')) return 'You do not have permission.';
    if (msg.contains('404')) return 'Nominee not found.';
    return msg;
  }
}
