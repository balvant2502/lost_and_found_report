import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime date;
  final bool isLost;
  final String reportedBy;
  final String reporterName;
  final String university;
  final bool isResolved;
  final String? imageUrl;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.isLost,
    required this.reportedBy,
    required this.reporterName,
    required this.university,
    this.isResolved = false,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFound => !isLost;

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
      date: parseDate(map['date']),
      isLost: map['isLost'] as bool? ?? true,
      reportedBy: map['reportedBy'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? 'Student',
      university: map['university'] as String? ?? '',
      isResolved: map['isResolved'] as bool? ?? false,
      imageUrl: map['imageUrl'] as String?,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'date': date.toIso8601String(),
      'isLost': isLost,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'university': university,
      'isResolved': isResolved,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? date,
    bool? isLost,
    String? reportedBy,
    String? reporterName,
    String? university,
    bool? isResolved,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      isLost: isLost ?? this.isLost,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterName: reporterName ?? this.reporterName,
      university: university ?? this.university,
      isResolved: isResolved ?? this.isResolved,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
