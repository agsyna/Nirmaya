class Report {
  final String recordId;
  final String type;
  final String title;
  final String? fileUrl;
  final String? originalContent;
  final String? aiSummary;
  final String? aiSummaryGeneratedAt;
  final String? documentDate;
  final String privacy;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final String? updatedAt;

  Report({
    required this.recordId,
    required this.type,
    required this.title,
    this.fileUrl,
    this.originalContent,
    this.aiSummary,
    this.aiSummaryGeneratedAt,
    this.documentDate,
    required this.privacy,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      recordId: json['recordId'] ?? '',
      type: json['type'] ?? 'other',
      title: json['title'] ?? 'Untitled',
      fileUrl: json['fileUrl'],
      originalContent: json['originalContent'],
      aiSummary: json['aiSummary'],
      aiSummaryGeneratedAt: json['aiSummaryGeneratedAt'],
      documentDate: json['documentDate'],
      privacy: json['privacy'] ?? 'private',
      metadata: json['metadata'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'type': type,
        'title': title,
        'fileUrl': fileUrl,
        'originalContent': originalContent,
        'aiSummary': aiSummary,
        'documentDate': documentDate,
        'privacy': privacy,
        'metadata': metadata,
        'createdAt': createdAt,
      };

  String get typeLabel {
    switch (type) {
      case 'report':
        return 'Report';
      case 'prescription':
        return 'Prescription';
      case 'scan':
        return 'Scan';
      case 'vaccination':
        return 'Vaccination';
      default:
        return 'Other';
    }
  }

  String get formattedDate {
    if (documentDate == null) return 'No date';
    try {
      final date = DateTime.parse(documentDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return documentDate!;
    }
  }
}
