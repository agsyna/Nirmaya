import 'package:flutter/material.dart';
import '../models/doctor_model.dart';

class AccessViewModel extends ChangeNotifier {
  late List<Doctor> doctors;

  AccessViewModel() {
    _initializeData();
  }

  void _initializeData() {
    // Hardcoded demo data
    doctors = [
      Doctor(
        id: '1',
        name: 'Doctor Name',
        phone: '9909874950',
        accessTill: '21st Aug 2024 07:00 PM',
        reports: 4,
        prescriptions: 5,
        accessDate: '23/03/2026',
        profileImageUrl: 'https://via.placeholder.com/50',
      ),
      Doctor(
        id: '2',
        name: 'Doctor Name',
        phone: '9909874950',
        accessTill: '21st Aug 2024 07:00 PM',
        reports: 4,
        prescriptions: 5,
        accessDate: '23/03/2026',
        profileImageUrl: 'https://via.placeholder.com/50',
      ),
      Doctor(
        id: '3',
        name: 'Doctor Name',
        phone: '9909874950',
        accessTill: '21st Aug 2024 07:00 PM',
        reports: 4,
        prescriptions: 5,
        accessDate: '23/03/2026',
        profileImageUrl: 'https://via.placeholder.com/50',
      ),
      Doctor(
        id: '4',
        name: 'Doctor Name',
        phone: '9909874950',
        accessTill: '21st Aug 2024 07:00 PM',
        reports: 4,
        prescriptions: 5,
        accessDate: '23/03/2026',
        profileImageUrl: 'https://via.placeholder.com/50',
      ),
    ];
  }

  List<Doctor> get doctorList => doctors;

  void updateAccess(String doctorId) {
    // Demo update - in real app, this would call backend
    notifyListeners();
  }
}
