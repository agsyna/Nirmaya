class Doctor {
  final String id;
  final String name;
  final String phone;
  final String accessTill;
  final int reports;
  final int prescriptions;
  final String accessDate;
  final String profileImageUrl;

  Doctor({
    required this.id,
    required this.name,
    required this.phone,
    required this.accessTill,
    required this.reports,
    required this.prescriptions,
    required this.accessDate,
    required this.profileImageUrl,
  });
}
