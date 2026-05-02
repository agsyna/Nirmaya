import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../../core/services/notification_service.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationService _medicationService = MedicationService();
  final NotificationService _notificationService = NotificationService();

  List<Medication> _medications = [];
  List<Medication> _activeMedications = [];
  List<MedicationLog> _todayLogs = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  List<Medication> get medications => _medications;
  List<Medication> get activeMedications => _activeMedications;
  List<MedicationLog> get todayLogs => _todayLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  // ==================== Initialize ====================
  Future<void> init() async {
    await loadMedications();
    await loadTodayLogs();
  }

  // ==================== Load All Medications ====================
  Future<void> loadMedications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medications = await _medicationService.getAllMedications();
      _activeMedications = await _medicationService.getActiveMedications();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== Load Today's Logs ====================
  Future<void> loadTodayLogs() async {
    try {
      _todayLogs = await _medicationService.getLogsForDate(_selectedDate);
      notifyListeners();
    } catch (_) {}
  }

  // ==================== Select Date ====================
  void selectDate(DateTime date) {
    _selectedDate = date;
    loadTodayLogs();
    notifyListeners();
  }

  // ==================== Add Medication ====================
  Future<bool> addMedication(Medication medication) async {
    try {
      final id = await _medicationService.addMedication(medication);

      // Schedule notifications for each reminder time
      for (int i = 0; i < medication.reminderTimes.length; i++) {
        final time = medication.reminderTimes[i];
        await _notificationService.scheduleMedicationReminder(
          id: id * 100 + i, // Unique notification ID
          medicineName: medication.name,
          dosage: medication.dosage,
          hour: time.hour,
          minute: time.minute,
        );
      }

      await loadMedications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== Update Medication ====================
  Future<bool> updateMedication(Medication medication) async {
    try {
      await _medicationService.updateMedication(medication);

      // Cancel old notifications
      if (medication.id != null) {
        for (int i = 0; i < 10; i++) {
          await _notificationService.cancelNotification(medication.id! * 100 + i);
        }
      }

      // Schedule new notifications
      if (medication.isActive) {
        for (int i = 0; i < medication.reminderTimes.length; i++) {
          final time = medication.reminderTimes[i];
          await _notificationService.scheduleMedicationReminder(
            id: medication.id! * 100 + i,
            medicineName: medication.name,
            dosage: medication.dosage,
            hour: time.hour,
            minute: time.minute,
          );
        }
      }

      await loadMedications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== Delete Medication ====================
  Future<bool> deleteMedication(int id) async {
    try {
      // Cancel notifications
      for (int i = 0; i < 10; i++) {
        await _notificationService.cancelNotification(id * 100 + i);
      }

      await _medicationService.deleteMedication(id);
      await loadMedications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== Toggle Active ====================
  Future<void> toggleActive(int id, bool isActive) async {
    await _medicationService.toggleMedicationActive(id, isActive);

    if (!isActive) {
      // Cancel notifications
      for (int i = 0; i < 10; i++) {
        await _notificationService.cancelNotification(id * 100 + i);
      }
    } else {
      // Re-schedule notifications
      final med = await _medicationService.getMedication(id);
      if (med != null) {
        for (int i = 0; i < med.reminderTimes.length; i++) {
          final time = med.reminderTimes[i];
          await _notificationService.scheduleMedicationReminder(
            id: id * 100 + i,
            medicineName: med.name,
            dosage: med.dosage,
            hour: time.hour,
            minute: time.minute,
          );
        }
      }
    }

    await loadMedications();
  }

  // ==================== Log Dose ====================
  Future<void> takeMedication(int medicationId, TimeOfDay scheduledTime) async {
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    await _medicationService.logMedication(
      medicationId: medicationId,
      scheduledTime: scheduledDateTime,
      status: 'taken',
      takenTime: now,
    );

    await loadTodayLogs();
  }

  // ==================== Skip Dose ====================
  Future<void> skipMedication(int medicationId, TimeOfDay scheduledTime) async {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    await _medicationService.logMedication(
      medicationId: medicationId,
      scheduledTime: scheduledDateTime,
      status: 'skipped',
    );

    await loadTodayLogs();
  }

  // Check if a medication dose was already logged at a given time
  bool isDoseLogged(int medicationId, TimeOfDay time) {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );

    return _todayLogs.any((log) =>
        log.medicationId == medicationId &&
        log.scheduledTime.hour == scheduledDateTime.hour &&
        log.scheduledTime.minute == scheduledDateTime.minute);
  }

  MedicationLog? getLogForDose(int medicationId, TimeOfDay time) {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );

    try {
      return _todayLogs.firstWhere((log) =>
          log.medicationId == medicationId &&
          log.scheduledTime.hour == scheduledDateTime.hour &&
          log.scheduledTime.minute == scheduledDateTime.minute);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
