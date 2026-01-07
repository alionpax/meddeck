import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meddeck/widgets/safe_network_image.dart';

void main() {
  testWidgets('SafeNetworkImage shows placeholder for empty url', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SafeNetworkImage(url: ''),
      ),
    ));

    // should show an Icon (photo)
    expect(find.byIcon(Icons.photo), findsOneWidget);
  });

  testWidgets('SafeNetworkImage shows progress for valid url (simulate)', (WidgetTester tester) async {
    // We can't perform real network I/O in widget tests reliably here, but ensure the widget builds when a URL is provided.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SafeNetworkImage(url: 'https://example.com/image.png'),
      ),
    ));

    // Should contain a CircularProgressIndicator placeholder while image loads
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
