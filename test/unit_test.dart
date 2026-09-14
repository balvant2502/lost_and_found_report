import 'package:campus_found/core/constants/app_constants.dart';
import 'package:campus_found/core/utils/date_helper.dart';
import 'package:campus_found/features/auth/models/user_model.dart';
import 'package:campus_found/features/chat/models/chat_room_model.dart';
import 'package:campus_found/features/chat/models/message_model.dart';
import 'package:campus_found/features/lost_found/models/item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants Tests', () {
    test('Categories contain all required categories', () {
      expect(AppConstants.categories, contains(AppConstants.categoryElectronics));
      expect(AppConstants.categories, contains(AppConstants.categoryBooks));
      expect(AppConstants.categories, contains(AppConstants.categoryAccessories));
      expect(AppConstants.categories, contains(AppConstants.categoryIdCards));
      expect(AppConstants.categories, contains(AppConstants.categoryOther));
      expect(AppConstants.categories.length, equals(5));
    });

    test('Max image size limit is exactly 10 MB', () {
      expect(AppConstants.maxImageSizeBytes, equals(10 * 1024 * 1024));
    });
  });

  group('ItemModel Tests', () {
    test('ItemModel serialization and getters work correctly', () {
      final item = ItemModel(
        id: 'item123',
        title: 'AirPods Pro',
        description: 'White case with green sticker',
        category: AppConstants.categoryElectronics,
        location: 'Library 3rd floor',
        date: DateTime(2026, 9, 14, 10, 0),
        isLost: true,
        reportedBy: 'user1',
        reporterName: 'Alex Rivera',
        university: 'Stanford University',
      );

      expect(item.isLost, isTrue);
      expect(item.isFound, isFalse);
      expect(item.isResolved, isFalse);

      final map = item.toMap();
      expect(map['title'], equals('AirPods Pro'));
      expect(map['category'], equals('Electronics'));
      expect(map['isLost'], isTrue);
      expect(map['university'], equals('Stanford University'));

      final reconstructed = ItemModel.fromMap(map, 'item123');
      expect(reconstructed.id, equals('item123'));
      expect(reconstructed.title, equals('AirPods Pro'));
      expect(reconstructed.location, equals('Library 3rd floor'));
      expect(reconstructed.isLost, isTrue);
      expect(reconstructed.isResolved, isFalse);
    });

    test('ItemModel copyWith updates fields properly', () {
      final item = ItemModel(
        id: 'item1',
        title: 'Notebook',
        description: 'Blue spiral notebook',
        category: AppConstants.categoryBooks,
        location: 'Hall B',
        date: DateTime.now(),
        isLost: false,
        reportedBy: 'user2',
        reporterName: 'Priya',
        university: 'MIT',
      );

      final resolvedItem = item.copyWith(isResolved: true);
      expect(resolvedItem.isResolved, isTrue);
      expect(resolvedItem.title, equals('Notebook'));
    });
  });

  group('UserModel Tests', () {
    test('UserModel serialization and deserialization work', () {
      final user = UserModel(
        uid: 'user123',
        name: 'Jordan Lee',
        email: 'jordan@mit.edu',
        university: 'MIT',
      );

      final map = user.toMap();
      expect(map['name'], equals('Jordan Lee'));
      expect(map['university'], equals('MIT'));

      final fromMapUser = UserModel.fromMap(map, 'user123');
      expect(fromMapUser.uid, equals('user123'));
      expect(fromMapUser.name, equals('Jordan Lee'));
      expect(fromMapUser.email, equals('jordan@mit.edu'));
      expect(fromMapUser.university, equals('MIT'));
    });
  });

  group('Chat Models Tests', () {
    test('ChatRoomModel participant resolution works', () {
      final room = ChatRoomModel(
        id: 'chat123',
        itemId: 'item123',
        itemTitle: 'Lost Keys',
        participants: ['userA', 'userB'],
        participantNames: {
          'userA': 'Alice',
          'userB': 'Bob',
        },
      );

      expect(room.getOtherParticipantName('userA'), equals('Bob'));
      expect(room.getOtherParticipantName('userB'), equals('Alice'));
    });

    test('MessageModel serialization works', () {
      final msg = MessageModel(
        id: 'msg1',
        senderId: 'userA',
        senderName: 'Alice',
        text: 'I found your keys at the reception!',
      );

      final map = msg.toMap();
      expect(map['text'], equals('I found your keys at the reception!'));
      expect(map['senderName'], equals('Alice'));
    });
  });

  group('DateHelper Tests', () {
    test('DateHelper format functions return expected strings', () {
      final date = DateTime(2026, 9, 14, 14, 30);
      expect(DateHelper.formatDate(date), equals('Sep 14, 2026'));
      expect(DateHelper.formatRelative(DateTime.now()), equals('Just now'));
    });
  });
}
