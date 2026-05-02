class AppConstants {
  AppConstants._();

  // API Configuration
  static const String apiBaseUrl = 'https://nirmaya-api.vercel.app/api/v1';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String onboardingKey = 'onboarding_complete';
  static const String userIdKey = 'user_id';
  static const String patientIdKey = 'patient_id';
  static const String userDataKey = 'user_data';

  // App Info
  static const String appName = 'Nirmaya';
  static const String appTagline = 'Your Health, Secured';

  // Pagination
  static const int defaultPageSize = 10;

  // Upload
  static const List<String> allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];
  static const int maxFileSizeMB = 10;

  // Report Types
  static const List<String> reportTypes = [
    'report',
    'prescription'
    // ,
    // 'scan',
    // 'vaccination',
    // 'other',
  ];

  // Medication Frequencies
  static const List<String> medicationFrequencies = [
    'Once daily',
    'Twice daily',
    'Thrice daily',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'Once a week',
    'As needed',
  ];

  // Medication Types
  static const List<String> medicationTypes = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drops',
    'Inhaler',
    'Cream',
    'Other',
  ];
}
