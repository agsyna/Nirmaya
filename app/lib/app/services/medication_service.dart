import 'package:sqflite/sqflite.dart';
import '../models/medication_model.dart';

class MedicationService {
  static final MedicationService _instance = MedicationService._internal();
  factory MedicationService() => _instance;
  MedicationService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/nirmaya_medications.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            dosage TEXT NOT NULL,
            frequency TEXT NOT NULL,
            reminder_times TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT,
            notes TEXT,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE medication_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            scheduled_time TEXT NOT NULL,
            taken_time TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ==================== Medications CRUD ====================
  Future<int> addMedication(Medication medication) async {
    final db = await database;
    return await db.insert('medications', medication.toMap());
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final results = await db.query(
      'medications',
      orderBy: 'is_active DESC, name ASC',
    );
    return results.map((map) => Medication.fromMap(map)).toList();
  }

  Future<List<Medication>> getActiveMedications() async {
    final db = await database;
    final results = await db.query(
      'medications',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return results.map((map) => Medication.fromMap(map)).toList();
  }

  Future<Medication?> getMedication(int id) async {
    final db = await database;
    final results = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Medication.fromMap(results.first);
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleMedicationActive(int id, bool isActive) async {
    final db = await database;
    await db.update(
      'medications',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Medication Logs ====================
  Future<void> logMedication({
    required int medicationId,
    required DateTime scheduledTime,
    required String status,
    DateTime? takenTime,
  }) async {
    final db = await database;
    await db.insert('medication_logs', {
      'medication_id': medicationId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'status': status,
    });
  }

  Future<List<MedicationLog>> getLogsForDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final results = await db.query(
      'medication_logs',
      where: 'scheduled_time >= ? AND scheduled_time < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return results.map((map) => MedicationLog.fromMap(map)).toList();
  }

  Future<List<MedicationLog>> getLogsForMedication(int medicationId) async {
    final db = await database;
    final results = await db.query(
      'medication_logs',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'scheduled_time DESC',
    );
    return results.map((map) => MedicationLog.fromMap(map)).toList();
  }

  Future<void> updateLogStatus(int logId, String status, {DateTime? takenTime}) async {
    final db = await database;
    final data = <String, dynamic>{'status': status};
    if (takenTime != null) {
      data['taken_time'] = takenTime.toIso8601String();
    }
    await db.update(
      'medication_logs',
      data,
      where: 'id = ?',
      whereArgs: [logId],
    );
  }
}
