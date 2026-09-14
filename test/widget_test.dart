import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_found/core/constants/app_constants.dart';
import 'package:campus_found/core/constants/app_theme.dart';
import 'package:campus_found/features/lost_found/models/item_model.dart';

void main() {
  testWidgets('Item card display test', (WidgetTester tester) async {
    final item = ItemModel(
      id: 'test_1',
      title: 'Graphing Calculator',
      description: 'TI-84 Plus in black case',
      category: AppConstants.categoryElectronics,
      location: 'Science Building Room 101',
      date: DateTime(2026, 9, 14),
      isLost: true,
      reportedBy: 'user_1',
      reporterName: 'Jordan Smith',
      university: 'Stanford University',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Card(
            child: ListTile(
              title: Text(item.title),
              subtitle: Text(item.location),
              trailing: Text(item.isLost ? 'LOST' : 'FOUND'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Graphing Calculator'), findsOneWidget);
    expect(find.text('Science Building Room 101'), findsOneWidget);
    expect(find.text('LOST'), findsOneWidget);
  });
}
