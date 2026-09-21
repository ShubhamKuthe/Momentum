class ReportFileEntry {
  const ReportFileEntry({
    required this.path,
    required this.displayName,
    required this.createdAt,
    required this.fileExtension,
  });

  final String path;
  final String displayName;
  final DateTime createdAt;
  final String fileExtension;

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'fileExtension': fileExtension,
    };
  }

  factory ReportFileEntry.fromMap(Map<String, dynamic> map) {
    return ReportFileEntry(
      path: map['path'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Momentum Report',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      fileExtension: map['fileExtension'] as String? ?? 'xlsx',
    );
  }
}
