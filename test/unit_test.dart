import 'package:campus_found/core/constants/app_constants.dart';
import 'package:campus_found/core/constants/campus_bounds.dart';
import 'package:campus_found/core/utils/date_helper.dart';
import 'package:campus_found/features/auth/models/user_model.dart';
import 'package:campus_found/features/chat/models/chat_room_model.dart';
import 'package:campus_found/features/chat/models/message_model.dart';
import 'package:campus_found/features/lost_found/models/item_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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

  group('CampusBounds & Geolocation Tests', () {
    test('Campus regions contain their respective centers and valid bounds', () {
      final stanford = CampusBounds.getRegion('Stanford University')!;
      expect(stanford.contains(stanford.center), isTrue);
      expect(stanford.landmarks.isNotEmpty, isTrue);

      final mit = CampusBounds.getRegion('MIT')!;
      expect(mit.contains(mit.center), isTrue);

      final berkeley = CampusBounds.getRegion('UC Berkeley')!;
      expect(berkeley.contains(berkeley.center), isTrue);
    });

    test('Campus region clamps coordinates outside boundaries', () {
      final stanford = CampusBounds.getRegion('Stanford University')!;
      // Point far outside Stanford (e.g. New York)
      final farPoint = const LatLng(40.7128, -74.0060);
      expect(stanford.contains(farPoint), isFalse);

      final clamped = stanford.clamp(farPoint);
      expect(stanford.contains(clamped), isTrue);
    });

    test('Closest landmark resolution inside campus', () {
      final stanford = CampusBounds.getRegion('Stanford University')!;
      final mainQuad = const LatLng(37.4275, -122.1697);
      final landmark = stanford.getClosestLandmark(mainQuad);
      expect(landmark, isNotNull);
      expect(landmark!.name, equals('Main Quad'));
    });

    test('CampusBounds resolves custom university dynamically', () async {
      final customRegion = await CampusBounds.resolveRegion('Oxford University');
      expect(customRegion, isNotNull);
      expect(customRegion.university, equals('Oxford University'));
      expect(customRegion.contains(customRegion.center), isTrue);
      expect(customRegion.bounds.north, greaterThan(customRegion.bounds.south));
      expect(customRegion.bounds.east, greaterThan(customRegion.bounds.west));

      // After resolving, synchronous lookup should also retrieve it from cache
      final cached = CampusBounds.getRegion('Oxford University');
      expect(cached, isNotNull);
      expect(cached!.university, equals('Oxford University'));
    });

    test('CampusBounds registers and retrieves manual custom region', () {
      final testRegion = CampusRegion(
        university: 'Custom Tech Institute',
        center: const LatLng(12.9716, 77.5946),
        bounds: LatLngBounds(
          const LatLng(12.9600, 77.5800),
          const LatLng(12.9800, 77.6100),
        ),
        isDynamicallyResolved: true,
      );

      CampusBounds.registerCustomRegion(testRegion);

      final retrieved = CampusBounds.getRegion('Custom Tech Institute');
      expect(retrieved, isNotNull);
      expect(retrieved!.center.latitude, equals(12.9716));
      expect(retrieved.isDynamicallyResolved, isTrue);
      expect(retrieved.contains(testRegion.center), isTrue);
    });
  });

  group('ItemModel Tests', () {
    test('ItemModel serialization with latitude and longitude', () {
      final item = ItemModel(
        id: 'item123',
        title: 'AirPods Pro',
        description: 'White case with green sticker',
        category: AppConstants.categoryElectronics,
        location: 'Main Quad, Stanford University',
        latitude: 37.4275,
        longitude: -122.1697,
        date: DateTime(2026, 9, 14, 10, 0),
        isLost: true,
        reportedBy: 'user1',
        reporterName: 'Alex Rivera',
        university: 'Stanford University',
      );

      expect(item.isLost, isTrue);
      expect(item.isFound, isFalse);
      expect(item.isResolved, isFalse);
      expect(item.hasCoordinates, isTrue);
      expect(item.latitude, equals(37.4275));
      expect(item.longitude, equals(-122.1697));

      final map = item.toMap();
      expect(map['title'], equals('AirPods Pro'));
      expect(map['category'], equals('Electronics'));
      expect(map['isLost'], isTrue);
      expect(map['university'], equals('Stanford University'));
      expect(map['latitude'], equals(37.4275));
      expect(map['longitude'], equals(-122.1697));

      final reconstructed = ItemModel.fromMap(map, 'item123');
      expect(reconstructed.id, equals('item123'));
      expect(reconstructed.title, equals('AirPods Pro'));
      expect(reconstructed.location, equals('Main Quad, Stanford University'));
      expect(reconstructed.latitude, equals(37.4275));
      expect(reconstructed.longitude, equals(-122.1697));
      expect(reconstructed.hasCoordinates, isTrue);
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
