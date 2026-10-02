import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime date;
  final bool isLost;
  final String reportedBy;
  final String reporterName;
  final String university;
  final bool isResolved;
  final String? imageUrl;
  final String? securityQuestion;
  final String? securityAnswer;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    required this.date,
    required this.isLost,
    required this.reportedBy,
    required this.reporterName,
    required this.university,
    this.isResolved = false,
    this.imageUrl,
    this.securityQuestion,
    this.securityAnswer,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFound => !isLost;
  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasSecurityQuestion =>
      securityQuestion != null && securityQuestion!.trim().isNotEmpty;

  /// Verifies a claimant's submitted answer against the founder's set answer (case-insensitive)
  bool verifySecurityAnswer(String? claimantAnswer) {
    if (securityAnswer == null || securityAnswer!.trim().isEmpty) {
      return true;
    }
    if (claimantAnswer == null || claimantAnswer.trim().isEmpty) {
      return false;
    }
    final cleanClaimant = claimantAnswer.trim().toLowerCase();
    final cleanExpected = securityAnswer!.trim().toLowerCase();
    return cleanClaimant == cleanExpected || cleanClaimant.contains(cleanExpected);
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return ItemModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      location: map['location'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      date: parseDate(map['date']),
      isLost: map['isLost'] as bool? ?? true,
      reportedBy: map['reportedBy'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? 'Student',
      university: map['university'] as String? ?? '',
      isResolved: map['isResolved'] as bool? ?? false,
      imageUrl: map['imageUrl'] as String?,
      securityQuestion: map['securityQuestion'] as String?,
      securityAnswer: map['securityAnswer'] as String?,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'date': date.toIso8601String(),
      'isLost': isLost,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'university': university,
      'isResolved': isResolved,
      'imageUrl': imageUrl,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? date,
    bool? isLost,
    String? reportedBy,
    String? reporterName,
    String? university,
    bool? isResolved,
    String? imageUrl,
    String? securityQuestion,
    String? securityAnswer,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      date: date ?? this.date,
      isLost: isLost ?? this.isLost,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterName: reporterName ?? this.reporterName,
      university: university ?? this.university,
      isResolved: isResolved ?? this.isResolved,
      imageUrl: imageUrl ?? this.imageUrl,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
