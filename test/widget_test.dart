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

    // Drena la secuencia del splash (delays encadenados + animaciones +
    // transición de navegación) para que no queden timers pendientes al
    // desmontar el árbol — de lo contrario el framework de test falla.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  });
}
