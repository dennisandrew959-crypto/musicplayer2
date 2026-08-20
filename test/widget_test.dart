// Basic smoke test for the music player app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:untitled4/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope with the audio handler override.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioHandlerProvider.overrideWithValue(AudioPlayerHandler()),
        ],
        child: const MyAppWrapper(),
      ),
    );

    // Verify the promo banner renders on the homepage.
    expect(find.text('Limited Offer'), findsOneWidget);
  });
}