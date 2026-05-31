import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexa_finance/app.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: VexaApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
