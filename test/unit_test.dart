import 'dart:convert';
import 'package:campus_found/core/constants/app_constants.dart';
import 'package:campus_found/core/constants/campus_bounds.dart';
import 'package:campus_found/core/utils/date_helper.dart';
import 'package:campus_found/core/utils/file_helper.dart';
import 'package:campus_found/features/auth/models/user_model.dart';
import 'package:campus_found/features/chat/models/chat_room_model.dart';
import 'package:campus_found/features/chat/models/message_model.dart';
import 'package:campus_found/features/lost_found/models/item_model.dart';
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

    test('Collection and subcollection constants are non-empty and distinct', () {
      expect(AppConstants.collectionUsers, equals('users'));
      expect(AppConstants.collectionItems, equals('items'));
      expect(AppConstants.collectionChats, equals('chats'));
      expect(AppConstants.subcollectionMessages, equals('messages'));
    });
  });

  group('CampusBounds & Circular Geometry Tests', () {
    test('All pre-configured universities have valid non-null regions, radius and centers', () {
      final preConfigured = [
        'Stanford University',
        'UC Berkeley',
        'MIT',
        'Harvard University',
        'UT Austin',
        'University of Washington',
        'NYU',
        'Georgia Tech',
        'UCLA',
        'Darshan University, Rajkot',
        'Dharmsinh Desai University (DDU)',
        'Marwadi University, Rajkot',
        'Saurashtra University, Rajkot',
        'Nirma University, Ahmedabad',
        'RK University, Rajkot',
      ];

      for (final uni in preConfigured) {
        final region = CampusBounds.getRegion(uni);
        expect(region, isNotNull, reason: 'Region should exist for $uni');
        expect(region!.contains(region.center), isTrue, reason: 'Region center should be inside circular bounds for $uni');
        expect(region.radiusMeters, greaterThan(0.0), reason: 'Radius must be positive for $uni');
        expect(region.bounds.north, greaterThan(region.bounds.south), reason: 'North bound must be greater than South for $uni');
        expect(region.bounds.east, greaterThan(region.bounds.west), reason: 'East bound must be greater than West for $uni');
      }
    });

    test('Circular containment and perimeter clamping in all 4 cardinal directions', () {
      final darshan = CampusBounds.getRegion('Darshan University, Rajkot')!;
      const distance = Distance();
      final center = darshan.center;
      final radius = darshan.radiusMeters; // 500.0m

      // Inside: point at 250m
      final insidePoint = distance.offset(center, 250, 45);
      expect(darshan.contains(insidePoint), isTrue);

      // Outside cardinal points at 1500m (North 0°, East 90°, South 180°, West 270°)
      final bearings = [0.0, 90.0, 180.0, 270.0];
      for (final bearing in bearings) {
        final farPoint = distance.offset(center, 1500, bearing);
        expect(darshan.contains(farPoint), isFalse, reason: '1500m away at bearing $bearing should be outside');

        final clamped = darshan.clamp(farPoint);
        expect(darshan.contains(clamped), isTrue, reason: 'Clamped point must be inside/on circular boundary');
        final distToClamped = distance.as(LengthUnit.Meter, center, clamped);
        expect(distToClamped, closeTo(radius, 1.0), reason: 'Clamped point should be on 500m radius circle');
      }
    });

    test('Closest landmark resolution inside campus', () {
      final stanford = CampusBounds.getRegion('Stanford University')!;
      final mainQuad = const LatLng(37.4275, -122.1697);
      final landmark = stanford.getClosestLandmark(mainQuad);
      expect(landmark, isNotNull);
      expect(landmark!.name, equals('Main Quad'));

      // Point far away from any landmark (> 300m) should return null
      const distance = Distance();
      final pointAway = distance.offset(mainQuad, 600, 90);
      final nullLandmark = stanford.getClosestLandmark(pointAway);
      expect(nullLandmark, isNull);
    });

    test('Fuzzy alias recognition matches university variations accurately', () {
      // Darshan University variations
      expect(CampusBounds.getRegion('darshan'), isNotNull);
      expect(CampusBounds.getRegion('Darshan University Rajkot'), isNotNull);
      expect(CampusBounds.getRegion('DARSHAN UNIVERSITY, RAJKOT'), isNotNull);
      expect(CampusBounds.getRegion('Darshan University, Rajkot')!.center.latitude, closeTo(22.4306, 0.001));

      // DDU variations
      expect(CampusBounds.getRegion('DDU'), isNotNull);
      expect(CampusBounds.getRegion('dharmsinh desai'), isNotNull);

      // Marwadi variations
      expect(CampusBounds.getRegion('marwadi university'), isNotNull);

      // Saurashtra variations
      expect(CampusBounds.getRegion('saurashtra'), isNotNull);

      // Nirma variations
      expect(CampusBounds.getRegion('nirma'), isNotNull);

      // RK University variations
      expect(CampusBounds.getRegion('rk university'), isNotNull);

      // Standard US universities
      expect(CampusBounds.getRegion('mit'), isNotNull);
      expect(CampusBounds.getRegion('berkeley'), isNotNull);
      expect(CampusBounds.getRegion('harvard'), isNotNull);
      expect(CampusBounds.getRegion('ucla'), isNotNull);
      expect(CampusBounds.getRegion('georgia tech'), isNotNull);
    });

    test('CampusBounds resolves custom university dynamically and caches it', () async {
      final customRegion = await CampusBounds.resolveRegion('Oxford University');
      expect(customRegion, isNotNull);
      expect(customRegion.university, equals('Oxford University'));
      expect(customRegion.contains(customRegion.center), isTrue);
      expect(customRegion.bounds.north, greaterThan(customRegion.bounds.south));
      expect(customRegion.bounds.east, greaterThan(customRegion.bounds.west));

      // Synchronous lookup from cache
      final cached = CampusBounds.getRegion('Oxford University');
      expect(cached, isNotNull);
      expect(cached!.university, equals('Oxford University'));
    });

    test('CampusBounds registers manual custom region', () {
      final testRegion = CampusRegion(
        university: 'Custom Tech Institute',
        center: const LatLng(12.9716, 77.5946),
        radiusMeters: 600.0,
        isDynamicallyResolved: true,
      );

      CampusBounds.registerCustomRegion(testRegion);

      final retrieved = CampusBounds.getRegion('Custom Tech Institute');
      expect(retrieved, isNotNull);
      expect(retrieved!.center.latitude, equals(12.9716));
      expect(retrieved.isDynamicallyResolved, isTrue);
      expect(retrieved.contains(testRegion.center), isTrue);
    });

    test('Darshan University coordinates are Gujarat Rajkot, NEVER Stanford California', () {
      final darshan = CampusBounds.getRegion('Darshan University Rajkot')!;
      expect(darshan.center.latitude, closeTo(22.4306, 0.001));
      expect(darshan.center.longitude, closeTo(70.7847, 0.001));
      expect(darshan.center.latitude, isNot(closeTo(37.4275, 1.0)));
    });

    test('Empty university string resolves to general campus fallback without throwing', () async {
      final fallback = await CampusBounds.resolveRegion('');
      expect(fallback, isNotNull);
      expect(fallback.contains(fallback.center), isTrue);
    });

    test('CampusBounds.isSameUniversity performs case-insensitive and alias comparison', () {
      // Direct case difference: 'harvard' and 'Harvard'
      expect(CampusBounds.isSameUniversity('harvard', 'Harvard'), isTrue);
      expect(CampusBounds.isSameUniversity('HARVARD', 'harvard'), isTrue);
      expect(CampusBounds.isSameUniversity('   Harvard   ', 'harvard'), isTrue);

      // Alias matching with region
      expect(CampusBounds.isSameUniversity('harvard', 'Harvard University'), isTrue);
      expect(CampusBounds.isSameUniversity('MIT', 'mit'), isTrue);
      expect(CampusBounds.isSameUniversity('darshan', 'Darshan University, Rajkot'), isTrue);
      expect(CampusBounds.isSameUniversity('Darshan University Rajkot', 'darshan university, rajkot'), isTrue);
      expect(CampusBounds.isSameUniversity('DDU', 'dharmsinh desai'), isTrue);

      // Custom university case-insensitive matching
      expect(CampusBounds.isSameUniversity('Custom Institute of Tech', 'custom institute of tech'), isTrue);
      expect(CampusBounds.isSameUniversity('Oxford', 'oxford'), isTrue);

      // Distinct universities must not match
      expect(CampusBounds.isSameUniversity('Harvard', 'Stanford'), isFalse);
      expect(CampusBounds.isSameUniversity('MIT', 'UCLA'), isFalse);

      // Null or empty handling
      expect(CampusBounds.isSameUniversity(null, 'Harvard'), isFalse);
      expect(CampusBounds.isSameUniversity('Harvard', null), isFalse);
      expect(CampusBounds.isSameUniversity('', 'Harvard'), isFalse);
    });

    test('CampusBounds.canonicalUniversityName normalizes names accurately', () {
      expect(CampusBounds.canonicalUniversityName('harvard'), equals('Harvard University'));
      expect(CampusBounds.canonicalUniversityName('HARVARD'), equals('Harvard University'));
      expect(CampusBounds.canonicalUniversityName('darshan'), equals('Darshan University, Rajkot'));
      expect(CampusBounds.canonicalUniversityName('mit'), equals('MIT'));
      expect(CampusBounds.canonicalUniversityName('My Custom College'), equals('My Custom College'));
      expect(CampusBounds.canonicalUniversityName('   '), equals('General Campus'));
    });
  });

  group('ItemModel Tests & Security Question Verification', () {
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

    test('ItemModel without coordinates handles null values gracefully', () {
      final item = ItemModel(
        id: 'itemNoCoords',
        title: 'Water Bottle',
        description: 'Metal hydroflask',
        category: AppConstants.categoryOther,
        location: 'Cafeteria Table 4',
        date: DateTime.now(),
        isLost: false,
        reportedBy: 'userX',
        reporterName: 'Jordan',
        university: 'MIT',
      );

      expect(item.latitude, isNull);
      expect(item.longitude, isNull);
      expect(item.hasCoordinates, isFalse);
      expect(item.isFound, isTrue);

      final map = item.toMap();
      expect(map['latitude'], isNull);
      expect(map['longitude'], isNull);

      final restored = ItemModel.fromMap(map, 'itemNoCoords');
      expect(restored.hasCoordinates, isFalse);
      expect(restored.latitude, isNull);
      expect(restored.longitude, isNull);
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

    test('ItemModel security question getters and serialization', () {
      final foundItem = ItemModel(
        id: 'found999',
        title: 'AirTag Keychain',
        description: 'Black leather keychain',
        category: AppConstants.categoryAccessories,
        location: 'Library 2nd Floor',
        date: DateTime.now(),
        isLost: false,
        reportedBy: 'founder1',
        reporterName: 'Carlos',
        university: 'Stanford University',
        securityQuestion: 'What letter is engraved on the metal ring?',
        securityAnswer: 'Letter K',
      );

      expect(foundItem.isFound, isTrue);
      expect(foundItem.hasSecurityQuestion, isTrue);
      expect(foundItem.securityQuestion, equals('What letter is engraved on the metal ring?'));
      expect(foundItem.securityAnswer, equals('Letter K'));

      final map = foundItem.toMap();
      final restored = ItemModel.fromMap(map, 'found999');
      expect(restored.hasSecurityQuestion, isTrue);
      expect(restored.securityQuestion, equals('What letter is engraved on the metal ring?'));
      expect(restored.securityAnswer, equals('Letter K'));
    });

    test('Item without security question returns hasSecurityQuestion false', () {
      final itemWithoutSec = ItemModel(
        id: 'itemPlain',
        title: 'Umbrella',
        description: 'Black umbrella',
        category: AppConstants.categoryOther,
        location: 'Auditorium',
        date: DateTime.now(),
        isLost: false,
        reportedBy: 'founder2',
        reporterName: 'Sam',
        university: 'UCLA',
        securityQuestion: null,
        securityAnswer: null,
      );

      expect(itemWithoutSec.hasSecurityQuestion, isFalse);
      // When no security question is configured, any verification is allowed
      expect(itemWithoutSec.verifySecurityAnswer('anything'), isTrue);
      expect(itemWithoutSec.verifySecurityAnswer(null), isTrue);
    });

    test('verifySecurityAnswer accurately validates claimant input', () {
      final secureItem = ItemModel(
        id: 'itemSec',
        title: 'Calculator',
        description: 'Scientific calculator found in lab',
        category: AppConstants.categoryElectronics,
        location: 'Room 302',
        date: DateTime.now(),
        isLost: false,
        reportedBy: 'founder3',
        reporterName: 'Neha',
        university: 'Darshan University, Rajkot',
        securityQuestion: 'What name is written on the back sticker?',
        securityAnswer: 'Aarav Patel',
      );

      // Exact match
      expect(secureItem.verifySecurityAnswer('Aarav Patel'), isTrue);

      // Case-insensitive match
      expect(secureItem.verifySecurityAnswer('aarav patel'), isTrue);
      expect(secureItem.verifySecurityAnswer('AARAV PATEL'), isTrue);

      // Extra whitespace tolerance
      expect(secureItem.verifySecurityAnswer('   Aarav Patel   '), isTrue);

      // Substring match
      expect(secureItem.verifySecurityAnswer('The name is Aarav Patel on the sticker'), isTrue);

      // Wrong answers rejected
      expect(secureItem.verifySecurityAnswer('Rohit Sharma'), isFalse);
      expect(secureItem.verifySecurityAnswer('Aarav Shah'), isFalse);

      // Empty or null answers rejected
      expect(secureItem.verifySecurityAnswer(''), isFalse);
      expect(secureItem.verifySecurityAnswer('   '), isFalse);
      expect(secureItem.verifySecurityAnswer(null), isFalse);
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
      expect(map['uid'], equals('user123'));
      expect(map['name'], equals('Jordan Lee'));
      expect(map['email'], equals('jordan@mit.edu'));
      expect(map['university'], equals('MIT'));

      final fromMapUser = UserModel.fromMap(map, 'user123');
      expect(fromMapUser.uid, equals('user123'));
      expect(fromMapUser.name, equals('Jordan Lee'));
      expect(fromMapUser.email, equals('jordan@mit.edu'));
      expect(fromMapUser.university, equals('MIT'));
    });

    test('UserModel copyWith works correctly', () {
      final user = UserModel(
        uid: 'user123',
        name: 'Jordan Lee',
        email: 'jordan@mit.edu',
        university: 'MIT',
      );

      final updated = user.copyWith(university: 'Darshan University, Rajkot');
      expect(updated.university, equals('Darshan University, Rajkot'));
      expect(updated.name, equals('Jordan Lee'));
      expect(updated.uid, equals('user123'));
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
        lastMessage: 'Let\'s meet at library',
        lastMessageTime: DateTime.now(),
      );

      expect(room.getOtherParticipantName('userA'), equals('Bob'));
      expect(room.getOtherParticipantName('userB'), equals('Alice'));

      final emptyRoom = ChatRoomModel(
        id: 'chatEmpty',
        itemId: 'itemX',
        itemTitle: 'Lost Bag',
        participants: ['userSolo'],
        participantNames: {'userSolo': 'Solo User'},
      );
      expect(emptyRoom.getOtherParticipantName('userSolo'), equals('Campus Member'));
    });

    test('ChatRoomModel serialization and deserialization work', () {
      final room = ChatRoomModel(
        id: 'chat456',
        itemId: 'item456',
        itemTitle: 'Blue Backpack',
        participants: ['u1', 'u2'],
        participantNames: {'u1': 'User One', 'u2': 'User Two'},
        lastMessage: 'Got it',
      );

      final map = room.toMap();
      expect(map['itemId'], equals('item456'));
      expect(map['itemTitle'], equals('Blue Backpack'));
      expect(map['participants'], contains('u1'));

      final restored = ChatRoomModel.fromMap(map, 'chat456');
      expect(restored.id, equals('chat456'));
      expect(restored.itemTitle, equals('Blue Backpack'));
      expect(restored.getOtherParticipantName('u1'), equals('User Two'));
    });

    test('MessageModel serialization works', () {
      final msg = MessageModel(
        id: 'msg1',
        senderId: 'userA',
        senderName: 'Alice',
        text: 'I found your keys at the reception!',
        timestamp: DateTime(2026, 9, 14, 15, 30),
      );

      final map = msg.toMap();
      expect(map['text'], equals('I found your keys at the reception!'));
      expect(map['senderName'], equals('Alice'));
      expect(map['senderId'], equals('userA'));

      final restored = MessageModel.fromMap(map, 'msg1');
      expect(restored.id, equals('msg1'));
      expect(restored.text, equals('I found your keys at the reception!'));
      expect(restored.senderName, equals('Alice'));
    });
  });

  group('DateHelper Tests', () {
    test('DateHelper format functions return expected strings', () {
      final date = DateTime(2026, 9, 14, 14, 30);
      expect(DateHelper.formatDate(date), equals('Sep 14, 2026'));
      expect(DateHelper.formatDateTime(date), contains('Sep 14, 2026'));
      expect(DateHelper.formatTime(date), contains('2:30'));
    });

    test('DateHelper formatRelative handles various time intervals', () {
      final now = DateTime.now();

      // Just now (< 1 min)
      expect(DateHelper.formatRelative(now.subtract(const Duration(seconds: 15))), equals('Just now'));

      // Minutes ago (< 60 min)
      expect(DateHelper.formatRelative(now.subtract(const Duration(minutes: 10))), equals('10m ago'));

      // Hours ago (< 24 h)
      expect(DateHelper.formatRelative(now.subtract(const Duration(hours: 3))), equals('3h ago'));

      // Days ago (< 7 d)
      expect(DateHelper.formatRelative(now.subtract(const Duration(days: 4))), equals('4d ago'));

      // Older date (>= 7 d)
      final olderDate = now.subtract(const Duration(days: 15));
      expect(DateHelper.formatRelative(olderDate), isNot(contains('ago')));
    });
  });

  group('FileHelper & Portable Base64 Image Tests', () {
    test('isBase64ImageUrl correctly detects Base64 data URLs', () {
      expect(FileHelper.isBase64ImageUrl('data:image/jpeg;base64,/9j/4AAQSkZJRg=='), isTrue);
      expect(FileHelper.isBase64ImageUrl('data:image/png;base64,iVBORw0KGgo=='), isTrue);
      expect(FileHelper.isBase64ImageUrl('https://res.cloudinary.com/demo/image/upload/sample.jpg'), isFalse);
      expect(FileHelper.isBase64ImageUrl('C:\\Users\\test\\item_images\\test.jpg'), isFalse);
      expect(FileHelper.isBase64ImageUrl('/data/user/0/item_images/test.jpg'), isFalse);
      expect(FileHelper.isBase64ImageUrl(''), isFalse);
      expect(FileHelper.isBase64ImageUrl(null), isFalse);
    });

    test('decodeBase64Image accurately decodes data URLs and raw Base64', () {
      final sampleBytes = [1, 2, 3, 4, 5];
      final encoded = base64Encode(sampleBytes);
      final dataUrl = 'data:image/jpeg;base64,$encoded';

      final decodedFromUrl = FileHelper.decodeBase64Image(dataUrl);
      expect(decodedFromUrl, isNotNull);
      expect(decodedFromUrl, equals(sampleBytes));

      final decodedFromRaw = FileHelper.decodeBase64Image(encoded);
      expect(decodedFromRaw, isNotNull);
      expect(decodedFromRaw, equals(sampleBytes));

      expect(FileHelper.decodeBase64Image(null), isNull);
      expect(FileHelper.decodeBase64Image(''), isNull);
      expect(FileHelper.decodeBase64Image('invalid!!!base64'), isNull);
    });

    test('getPortableImageDataUrl returns existing URLs or data URLs unchanged', () async {
      const dataUrl = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
      const httpsUrl = 'https://res.cloudinary.com/demo/sample.jpg';

      expect(await FileHelper.getPortableImageDataUrl(dataUrl), equals(dataUrl));
      expect(await FileHelper.getPortableImageDataUrl(httpsUrl), equals(httpsUrl));
      expect(await FileHelper.getPortableImageDataUrl(''), isNull);
    });
  });
}
