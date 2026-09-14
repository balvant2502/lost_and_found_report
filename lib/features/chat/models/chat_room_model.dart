import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  ChatRoomModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.participants,
    required this.participantNames,
    this.lastMessage = '',
    this.lastMessageTime,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final participantsList = (map['participants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final namesMap = (map['participantNames'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())) ??
        {};

    return ChatRoomModel(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      itemTitle: map['itemTitle'] as String? ?? 'Campus Item',
      participants: participantsList,
      participantNames: namesMap,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: parseDate(map['lastMessageTime']),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String getOtherParticipantName(String currentUserId) {
    for (final entry in participantNames.entries) {
      if (entry.key != currentUserId) {
        return entry.value;
      }
    }
    return 'Campus Member';
  }
}
