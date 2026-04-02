import 'package:flutter/material.dart';
import '../services/share_service.dart';

class ShareViewModel extends ChangeNotifier {
  final ShareService _shareService = ShareService();

  // Expiry options
  List<String> expiryOptions = [
    '1 hour',
    '24 hours',
    '7 days',
    '30 days',
  ];
  String? selectedExpiry;

  // Access scope options
  Map<String, bool> accessScope = {
    'reports': false,
    'prescriptions': false,
    'history': false,
  };

  // Max access count
  int maxAccessCount = 5;

  // Generated token/link
  String? generatedLink;
  String? generatedToken;

  // Error state
  String? errorMessage;

  // Loading state
  bool isLoading = false;

  void selectExpiry(String expiry) {
    selectedExpiry = expiry;
    errorMessage = null; // Clear error on user interaction
    notifyListeners();
  }

  void toggleAccessScope(String key) {
    accessScope[key] = !accessScope[key]!;
    errorMessage = null; // Clear error on user interaction
    notifyListeners();
  }

  void setMaxAccessCount(int count) {
    maxAccessCount = count;
    errorMessage = null; // Clear error on user interaction
    notifyListeners();
  }

  // Generate share link by calling backend
  Future<bool> generateShareLink({
    required String patientId,
  }) async {
    // Validate before generating
    if (selectedExpiry == null) {
      errorMessage = 'Please select expiry time';
      notifyListeners();
      return false;
    }

    if (!accessScope.values.any((v) => v)) {
      errorMessage = 'Please select at least one access scope';
      notifyListeners();
      return false;
    }

    // Clear error if validation passes
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      // Call backend service
      final response = await _shareService.createShareToken(
        patientId: patientId,
        expiryTime: selectedExpiry!,
        accessScope: getSelectedScopes(),
        maxAccessCount: maxAccessCount,
      );

      generatedToken = response.token;
      generatedLink = response.link;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void resetForm() {
    selectedExpiry = null;
    accessScope.updateAll((key, value) => false);
    maxAccessCount = 5;
    generatedLink = null;
    generatedToken = null;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  List<String> getSelectedScopes() {
    return accessScope.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }
}
