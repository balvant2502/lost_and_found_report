import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  List<ChatRoomModel> _chatRooms = [];
  List<MessageModel> _currentMessages = [];
  bool _isLoadingRooms = false;
  bool _isLoadingMessages = false;
  String? _activeChatRoomId;
  String? _errorMessage;

  List<ChatRoomModel> get chatRooms => _chatRooms;
  List<MessageModel> get currentMessages => _currentMessages;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get activeChatRoomId => _activeChatRoomId;
  String? get errorMessage => _errorMessage;

  /// Initializes real-time listener for all chat rooms the user is participating in
  void initUserChats(String currentUserId) {
    if (currentUserId.isEmpty) return;

    _isLoadingRooms = true;
    notifyListeners();

    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = _firestore
        .collection(AppConstants.collectionChats)
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        _chatRooms = snapshot.docs.map((doc) {
          return ChatRoomModel.fromMap(doc.data(), doc.id);
        }).toList();

        // Sort by last message time descending
        _chatRooms.sort((a, b) {
          final timeA = a.lastMessageTime ?? a.createdAt;
          final timeB = b.lastMessageTime ?? b.createdAt;
          return timeB.compareTo(timeA);
        });

        _isLoadingRooms = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to chat rooms: $error');
        _isLoadingRooms = false;
        notifyListeners();
      },
    );
  }

  /// Finds existing conversation or creates a new one for an item
  Future<String?> getOrCreateChatRoom({
    required String itemId,
    required String itemTitle,
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      // Query if chat room already exists between these users for this item
      final existingQuery = await _firestore
          .collection(AppConstants.collectionChats)
          .where('itemId', isEqualTo: itemId)
          .where('participants', arrayContains: currentUserId)
          .get();

      for (final doc in existingQuery.docs) {
        final participants =
            (doc.data()['participants'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new chat room
      final newDocRef = _firestore.collection(AppConstants.collectionChats).doc();
      final newRoom = ChatRoomModel(
        id: newDocRef.id,
        itemId: itemId,
        itemTitle: itemTitle,
        participants: [currentUserId, otherUserId],
        participantNames: {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        lastMessage: 'Conversation started',
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await newDocRef.set(newRoom.toMap());
      return newDocRef.id;
    } catch (e) {
      debugPrint('Error getting or creating chat room: $e');
      _errorMessage = 'Failed to open chat: $e';
      notifyListeners();
      return null;
    }
  }

  /// Listens to real-time messages within a specific chat room
  void listenToMessages(String chatRoomId) {
    if (_activeChatRoomId == chatRoomId && _messagesSubscription != null) return;

    _activeChatRoomId = chatRoomId;
    _isLoadingMessages = true;
    _currentMessages = [];
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _firestore
        .collection(AppConstants.collectionChats)
        .doc(chatRoomId)
        .collection(AppConstants.subcollectionMessages)
        .snapshots()
        .listen(
      (snapshot) {
        _currentMessages = snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data(), doc.id);
        }).toList();

        // Sort chronologically (oldest to newest)
        _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        _isLoadingMessages = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to messages: $error');
        _isLoadingMessages = false;
        notifyListeners();
      },
    );
  }

  /// Sends a message and updates the parent chat room's last message snippet
  Future<bool> sendMessage({
    required String chatRoomId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    try {
      final now = DateTime.now();
      final messagesCol = _firestore
          .collection(AppConstants.collectionChats)
          .doc(chatRoomId)
          .collection(AppConstants.subcollectionMessages);

      final msgDoc = messagesCol.doc();
      final message = MessageModel(
        id: msgDoc.id,
        senderId: senderId,
        senderName: senderName,
        text: trimmed,
        timestamp: now,
      );

      await msgDoc.set(message.toMap());

      // Update last message in parent chat room
      await _firestore
          .collection(AppConstants.collectionChats)
          .doc(chatRoomId)
          .update({
        'lastMessage': trimmed,
        'lastMessageTime': now.toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      _errorMessage = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  void closeActiveChat() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _activeChatRoomId = null;
    _currentMessages = [];
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
