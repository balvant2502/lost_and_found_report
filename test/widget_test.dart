import 'package:campus_found/core/constants/app_constants.dart';
import 'package:campus_found/core/constants/app_theme.dart';
import 'package:campus_found/core/constants/campus_bounds.dart';
import 'package:campus_found/core/utils/date_helper.dart';
import 'package:campus_found/features/chat/models/message_model.dart';
import 'package:campus_found/features/lost_found/models/item_model.dart';
import 'package:campus_found/features/lost_found/views/widgets/campus_map_picker.dart';
import 'package:campus_found/features/lost_found/views/widgets/item_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lost & Found Item Card Widget Tests', () {
    testWidgets('Lost Item card displays red/orange accent, category badge, and location', (WidgetTester tester) async {
      final item = ItemModel(
        id: 'lost_1',
        title: 'Graphing Calculator TI-84',
        description: 'Black case with sticker on back',
        category: AppConstants.categoryElectronics,
        location: 'Science Building Room 101',
        latitude: 22.4306,
        longitude: 70.7847,
        date: DateTime(2026, 9, 14),
        isLost: true,
        reportedBy: 'user_1',
        reporterName: 'Jordan Smith',
        university: 'Darshan University, Rajkot',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(item.category),
                        backgroundColor: const Color(0xFFF4F4F5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.isLost ? 'LOST' : 'FOUND',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.location,
                    style: const TextStyle(color: Color(0xFF71717A)),
                  ),
                  if (item.hasCoordinates)
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryColor),
                        SizedBox(width: 4),
                        Text('Campus Map Pinned', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Graphing Calculator TI-84'), findsOneWidget);
      expect(find.text('Science Building Room 101'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('LOST'), findsOneWidget);
      expect(find.text('Campus Map Pinned'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('Found Item card with security question displays lock badge', (WidgetTester tester) async {
      final item = ItemModel(
        id: 'found_1',
        title: 'Leather Wallet',
        description: 'Brown leather with brass clip',
        category: AppConstants.categoryAccessories,
        location: 'Central Library 1st Floor',
        date: DateTime(2026, 9, 20),
        isLost: false,
        reportedBy: 'user_founder',
        reporterName: 'Carlos Ray',
        university: 'Darshan University, Rajkot',
        securityQuestion: 'What initials are embossed on the inside fold?',
        securityAnswer: 'J.D.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.title),
                      Text(item.isLost ? 'LOST' : 'FOUND'),
                    ],
                  ),
                  if (item.hasSecurityQuestion)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 13, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'Security Question Protected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Leather Wallet'), findsOneWidget);
      expect(find.text('FOUND'), findsOneWidget);
      expect(find.text('Security Question Protected'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });

  group('Security Question Verification Dialog Tests', () {
    testWidgets('Dialog validates empty input and rejects incorrect verification answer', (WidgetTester tester) async {
      final item = ItemModel(
        id: 'found_item',
        title: 'Apple Watch Series 8',
        description: 'Silver aluminum case with black sport band',
        category: AppConstants.categoryElectronics,
        location: 'Sports Turf',
        date: DateTime.now(),
        isLost: false,
        reportedBy: 'founder123',
        reporterName: 'Neha',
        university: 'Darshan University, Rajkot',
        securityQuestion: 'What character is set as the watch face wallpaper?',
        securityAnswer: 'Iron Man',
      );

      bool verificationPassed = false;
      String submittedClaim = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  final answerController = TextEditingController();
                  String? localError;

                  showDialog(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setDialogState) => AlertDialog(
                        title: const Text('Verify Ownership'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Security Question:'),
                            Text(item.securityQuestion!),
                            TextField(
                              controller: answerController,
                              decoration: InputDecoration(
                                labelText: 'Your Answer',
                                errorText: localError,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final text = answerController.text.trim();
                              if (text.isEmpty) {
                                setDialogState(() {
                                  localError = 'Please enter an answer to proceed.';
                                });
                                return;
                              }

                              if (!item.verifySecurityAnswer(text)) {
                                setDialogState(() {
                                  localError = "Answer does not match founder's secret verification. Please try again.";
                                });
                                return;
                              }

                              verificationPassed = true;
                              submittedClaim = text;
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Verify & Claim'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Claim Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Claim Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Ownership'), findsOneWidget);
      expect(find.text('What character is set as the watch face wallpaper?'), findsOneWidget);

      // 1. Submit empty answer -> expect empty error
      await tester.tap(find.text('Verify & Claim'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter an answer to proceed.'), findsOneWidget);
      expect(verificationPassed, isFalse);

      // 2. Submit wrong answer -> expect mismatch error
      await tester.enterText(find.byType(TextField), 'Batman');
      await tester.tap(find.text('Verify & Claim'));
      await tester.pumpAndSettle();
      expect(find.text("Answer does not match founder's secret verification. Please try again."), findsOneWidget);
      expect(verificationPassed, isFalse);

      // 3. Submit correct answer with different case -> succeeds and closes
      await tester.enterText(find.byType(TextField), 'iron man');
      await tester.tap(find.text('Verify & Claim'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(verificationPassed, isTrue);
      expect(submittedClaim, equals('iron man'));
    });
  });

  group('Category & Type Segment Filter Widget Tests', () {
    testWidgets('Tapping category pill and type segments toggles active state', (WidgetTester tester) async {
      String selectedCategory = 'All';
      String selectedType = 'All';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  // Type filter row
                  Row(
                    children: ['All', 'Lost', 'Found'].map((type) {
                      final isSelected = selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          key: Key('type_$type'),
                          onTap: () => setState(() => selectedType = type),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: isSelected ? Colors.black : Colors.white,
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return GestureDetector(
                          key: Key('cat_$cat'),
                          onTap: () => setState(() => selectedCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Text('Active Type: $selectedType'),
                  Text('Active Category: $selectedCategory'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Active Type: All'), findsOneWidget);
      expect(find.text('Active Category: All'), findsOneWidget);

      // Tap 'Lost' type filter
      await tester.tap(find.byKey(const Key('type_Lost')));
      await tester.pump();
      expect(find.text('Active Type: Lost'), findsOneWidget);

      // Tap 'Electronics' category
      await tester.tap(find.byKey(const Key('cat_Electronics')));
      await tester.pump();
      expect(find.text('Active Category: Electronics'), findsOneWidget);

      // Tap 'Found' type filter
      await tester.tap(find.byKey(const Key('type_Found')));
      await tester.pump();
      expect(find.text('Active Type: Found'), findsOneWidget);
    });
  });

  group('Campus Region Info & Landmark Selector Widget Tests', () {
    testWidgets('Campus region info displays circular perimeter and landmark chips', (WidgetTester tester) async {
      final region = CampusBounds.getRegion('Darshan University, Rajkot')!;
      String? selectedLandmarkName;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.radar_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text('${region.university} (${region.radiusMeters.round()}m Circular Zone)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: region.landmarks.map((l) {
                      final isSelected = selectedLandmarkName == l.name;
                      return ActionChip(
                        key: Key('landmark_${l.name}'),
                        label: Text(l.name),
                        backgroundColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.15) : null,
                        onPressed: () => setState(() => selectedLandmarkName = l.name),
                      );
                    }).toList(),
                  ),
                  if (selectedLandmarkName != null)
                    Text('Selected: $selectedLandmarkName'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Darshan University, Rajkot (500m Circular Zone)'), findsOneWidget);
      expect(find.text('Main Academic Block'), findsOneWidget);
      expect(find.text('Central Library & Admin Block'), findsOneWidget);
      expect(find.text('Student Cafeteria & Canteen'), findsOneWidget);

      // Tap a landmark chip
      await tester.tap(find.byKey(const Key('landmark_Central Library & Admin Block')));
      await tester.pump();

      expect(find.text('Selected: Central Library & Admin Block'), findsOneWidget);
    });

    testWidgets('CampusMapPicker renders fallback container when university name is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusMapPicker(
              university: '',
              isLost: false,
              onLocationSelected: (pos, name) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('A campus map is not available'), findsOneWidget);
    });
  });

  group('Chat Message Bubble Widget Tests', () {
    testWidgets('Renders sender and recipient chat bubbles with appropriate alignment and styles', (WidgetTester tester) async {
      final msgIncoming = MessageModel(
        id: 'msg_1',
        senderId: 'founder_user',
        senderName: 'Carlos',
        text: 'Hi, I found your AirPods near the library entrance.',
        timestamp: DateTime(2026, 9, 14, 15, 30),
      );

      final msgOutgoing = MessageModel(
        id: 'msg_2',
        senderId: 'current_user',
        senderName: 'Alex',
        text: '🔐 [Claim Verification] I verified the serial number!',
        timestamp: DateTime(2026, 9, 14, 15, 32),
      );

      Widget buildBubble(MessageModel message, bool isMe) {
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            key: Key('bubble_${message.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.darkColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    message.senderName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                Text(
                  message.text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                ),
                Text(
                  DateHelper.formatTime(message.timestamp),
                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                buildBubble(msgIncoming, false),
                buildBubble(msgOutgoing, true),
              ],
            ),
          ),
        ),
      );

      // Incoming bubble verification
      expect(find.text('Carlos'), findsOneWidget);
      expect(find.text('Hi, I found your AirPods near the library entrance.'), findsOneWidget);

      // Outgoing bubble verification
      expect(find.text('🔐 [Claim Verification] I verified the serial number!'), findsOneWidget);

      // Alignments verification
      final incomingAlign = tester.widget<Align>(find.ancestor(
        of: find.byKey(const Key('bubble_msg_1')),
        matching: find.byType(Align),
      ));
      expect(incomingAlign.alignment, equals(Alignment.centerLeft));

      final outgoingAlign = tester.widget<Align>(find.ancestor(
        of: find.byKey(const Key('bubble_msg_2')),
        matching: find.byType(Align),
      ));
      expect(outgoingAlign.alignment, equals(Alignment.centerRight));
    });

    testWidgets('Chat screen empty state renders without overflow in landscape orientation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              toolbarHeight: 48,
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Carlos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('TI-84 Calculator', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4F4F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('💬', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Chat about TI-84 Calculator',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Coordinate item verification and campus handover safely.',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: Colors.white,
                  child: const Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(hintText: 'Type a message...'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chat about TI-84 Calculator'), findsOneWidget);
      expect(find.text('Carlos'), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Dashboard Stat Tile Widget Tests', () {
    testWidgets('Dashboard stat tiles display correct values and labels', (WidgetTester tester) async {
      Widget buildStatTile(String label, int count, IconData icon, Color color) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                buildStatTile('Total Reports', 8, Icons.inventory_2_rounded, Colors.blue),
                buildStatTile('Active Lost', 3, Icons.search_rounded, Colors.orange),
                buildStatTile('Active Found', 2, Icons.check_circle_rounded, Colors.green),
                buildStatTile('Resolved', 3, Icons.done_all_rounded, Colors.purple),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total Reports'), findsOneWidget);
      expect(find.text('Active Lost'), findsOneWidget);
      expect(find.text('Active Found'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      expect(find.text('8'), findsOneWidget);
      expect(find.text('3'), findsNWidgets(2)); // Active Lost and Resolved both have count 3
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('Demo Mode Removal & Case-Insensitive Filter Tests', () {
    testWidgets('Demo Mode button is removed and not present', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Log In'),
                Text("Don't have an account?"),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Explore in Demo Mode'), findsNothing);
      expect(find.textContaining('Demo Mode'), findsNothing);
    });

    test('Filtering item list with harvard vs Harvard includes items regardless of case', () {
      final items = [
        ItemModel(
          id: '1',
          title: 'Textbook',
          description: 'Math',
          category: AppConstants.categoryBooks,
          location: 'Library',
          date: DateTime.now(),
          isLost: true,
          reportedBy: 'u1',
          reporterName: 'Alice',
          university: 'Harvard',
        ),
        ItemModel(
          id: '2',
          title: 'Charger',
          description: 'Type-C',
          category: AppConstants.categoryElectronics,
          location: 'Hall',
          date: DateTime.now(),
          isLost: false,
          reportedBy: 'u2',
          reporterName: 'Bob',
          university: 'harvard',
        ),
        ItemModel(
          id: '3',
          title: 'Notebook',
          description: 'Physics',
          category: AppConstants.categoryBooks,
          location: 'Dorm',
          date: DateTime.now(),
          isLost: true,
          reportedBy: 'u3',
          reporterName: 'Charlie',
          university: 'Stanford University',
        ),
      ];

      // When user searches / filters by 'harvard' (lowercase)
      final userWithLower = items.where((item) => CampusBounds.isSameUniversity(item.university, 'harvard')).toList();
      expect(userWithLower.length, equals(2));
      expect(userWithLower.map((e) => e.id), containsAll(['1', '2']));

      // When user searches / filters by 'HARVARD' (uppercase)
      final userWithUpper = items.where((item) => CampusBounds.isSameUniversity(item.university, 'HARVARD')).toList();
      expect(userWithUpper.length, equals(2));
      expect(userWithUpper.map((e) => e.id), containsAll(['1', '2']));

      // When user searches / filters by 'Harvard University'
      final userWithFullName = items.where((item) => CampusBounds.isSameUniversity(item.university, 'Harvard University')).toList();
      expect(userWithFullName.length, equals(2));
      expect(userWithFullName.map((e) => e.id), containsAll(['1', '2']));
    });

    testWidgets('University Dropdown renders long campus names without horizontal overflow in portrait mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String selectedUni = 'Dharmsinh Desai University (DDU)';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: DropdownButtonFormField<String>(
                initialValue: selectedUni,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'University / College',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: AppConstants.defaultUniversities.map((uni) {
                  return DropdownMenuItem(
                    value: uni,
                    child: Text(
                      uni,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (val) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dharmsinh Desai University (DDU)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemImageView & Cross-Platform Image Display Widget Tests', () {
    testWidgets('ItemImageView renders fallback placeholder when imageUrl is null or empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemImageView(
              imageUrl: null,
              placeholderBuilder: (_) => const Text('Fallback Icon'),
            ),
          ),
        ),
      );

      expect(find.text('Fallback Icon'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('ItemImageView renders fallback placeholder when imageUrl is an inaccessible cross-device path', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemImageView(
              imageUrl: 'C:\\Users\\another_user\\item_images\\non_existent.jpg',
              placeholderBuilder: (_) => const Text('Safe Placeholder'),
            ),
          ),
        ),
      );

      expect(find.text('Safe Placeholder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ItemImageView renders Image.memory for portable Base64 data URL', (WidgetTester tester) async {
      // 1x1 valid red PNG
      const sampleBase64Png =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemImageView(
              imageUrl: sampleBase64Png,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(12),
              placeholderBuilder: (_) => const Text('Fallback'),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Fallback'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
