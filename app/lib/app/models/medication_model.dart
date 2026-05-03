import 'package:flutter/material.dart';

class Medication {
  final int? id;
  final String name;
  final String type; // Tablet, Capsule, Syrup, etc.
  final String dosage; // e.g., "10 mg"
  final String frequency; // e.g., "Twice daily"
  final List<int> daysOfWeek; // DateTime weekday values: 1 (Mon) to 7 (Sun)
  final List<TimeOfDay> reminderTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;

  Medication({
    this.id,
    required this.name,
    required this.type,
    required this.dosage,
    required this.frequency,
    required this.daysOfWeek,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    // Parse reminder times from stored string like "09:00,21:00"
    List<TimeOfDay> times = [];
    if (map['reminder_times'] != null) {
      final timeStrings = (map['reminder_times'] as String).split(',');
      times = timeStrings.map((t) {
        final parts = t.trim().split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    }

    List<int> days = [1, 2, 3, 4, 5, 6, 7];
    final rawDays = map['days_of_week'];
    if (rawDays != null && rawDays.toString().trim().isNotEmpty) {
      days =
          rawDays
              .toString()
              .split(',')
              .map((d) => int.tryParse(d.trim()))
              .whereType<int>()
              .where((d) => d >= 1 && d <= 7)
              .toSet()
              .toList()
            ..sort();
      if (days.isEmpty) {
        days = [1, 2, 3, 4, 5, 6, 7];
      }
    }

    return Medication(
      id: map['id'],
      name: map['name'] ?? '',
      type: map['type'] ?? 'Tablet',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? 'Once daily',
      daysOfWeek: days,
      reminderTimes: times,
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      notes: map['notes'],
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'dosage': dosage,
      'frequency': frequency,
      'days_of_week': daysOfWeek.join(','),
      'reminder_times': reminderTimes
          .map(
            (t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .join(','),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  Medication copyWith({
    int? id,
    String? name,
    String? type,
    String? dosage,
    String? frequency,
    List<int>? daysOfWeek,
    List<TimeOfDay>? reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedReminderTimes {
    return reminderTimes
        .map((t) {
          final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
          final period = t.period == DayPeriod.am ? 'AM' : 'PM';
          return '${hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $period';
        })
        .join(', ');
  }

  bool isScheduledOn(DateTime date) {
    return daysOfWeek.contains(date.weekday);
  }
}

class MedicationLog {
  final int? id;
  final int medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final String status; // 'taken', 'missed', 'skipped', 'pending'

  MedicationLog({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
  });

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'],
      medicationId: map['medication_id'],
      scheduledTime: DateTime.parse(map['scheduled_time']),
      takenTime: map['taken_time'] != null
          ? DateTime.parse(map['taken_time'])
          : null,
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'status': status,
    };
  }
}
