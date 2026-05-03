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
      _refreshScheduledMedications();
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
    _refreshScheduledMedications();
    loadTodayLogs();
    notifyListeners();
  }

  // ==================== Add Medication ====================
  Future<bool> addMedication(Medication medication) async {
    try {
      final id = await _medicationService.addMedication(medication);

      await _scheduleNotificationsForMedication(medication.copyWith(id: id));

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
        await _cancelNotificationsForMedication(medication.id!);
      }

      // Schedule new notifications
      if (medication.isActive) {
        await _scheduleNotificationsForMedication(medication);
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
      await _cancelNotificationsForMedication(id);

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
      await _cancelNotificationsForMedication(id);
    } else {
      // Re-schedule notifications
      final med = await _medicationService.getMedication(id);
      if (med != null) {
        await _scheduleNotificationsForMedication(med);
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

    return _todayLogs.any(
      (log) =>
          log.medicationId == medicationId &&
          log.scheduledTime.hour == scheduledDateTime.hour &&
          log.scheduledTime.minute == scheduledDateTime.minute,
    );
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
      return _todayLogs.firstWhere(
        (log) =>
            log.medicationId == medicationId &&
            log.scheduledTime.hour == scheduledDateTime.hour &&
            log.scheduledTime.minute == scheduledDateTime.minute,
      );
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _refreshScheduledMedications() {
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    _activeMedications = _medications.where((med) {
      if (!med.isActive) return false;

      final start = DateTime(
        med.startDate.year,
        med.startDate.month,
        med.startDate.day,
      );
      final end = med.endDate == null
          ? null
          : DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);

      if (selectedDay.isBefore(start)) return false;
      if (end != null && selectedDay.isAfter(end)) return false;

      return med.isScheduledOn(selectedDay);
    }).toList();
  }

  int _notificationId(int medicationId, int weekday, int slotIndex) {
    return medicationId * 1000 + (weekday * 10) + slotIndex;
  }

  Future<void> _cancelNotificationsForMedication(int medicationId) async {
    for (int day = 1; day <= 7; day++) {
      for (int slot = 0; slot < 10; slot++) {
        await _notificationService.cancelNotification(
          _notificationId(medicationId, day, slot),
        );
      }
    }
  }

  Future<void> _scheduleNotificationsForMedication(
    Medication medication,
  ) async {
    if (medication.id == null) return;

    final days = medication.daysOfWeek.toSet().where((d) => d >= 1 && d <= 7);
    for (final day in days) {
      for (int i = 0; i < medication.reminderTimes.length; i++) {
        final time = medication.reminderTimes[i];
        await _notificationService.scheduleWeeklyMedicationReminder(
          id: _notificationId(medication.id!, day, i),
          medicineName: medication.name,
          dosage: medication.dosage,
          weekday: day,
          hour: time.hour,
          minute: time.minute,
        );
      }
    }
  }
}
