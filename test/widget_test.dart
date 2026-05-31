// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:crest_achievers/main.dart';
import 'package:crest_achievers/services/firebase_service.dart';

void main() {
  testWidgets('App smoke test - verifies app builds and launches without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame with the necessary Provider.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FirebaseService(),
        child: const CrestAchieversApp(),
      ),
    );

    // Verify that our main App widget is mounted successfully.
    expect(find.byType(CrestAchieversApp), findsOneWidget);
  });
}
