import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'core/data/isar_service.dart';
import 'core/providers/isar_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  late Isar isar;
  try {
    isar = await openIsar().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Isar tardó demasiado al abrir'),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Error al inicializar: $e\n$stackTrace'),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // initializeDateFormatting es local y rápido; GoogleFonts se omite
  // del bloqueo para no colgar si no hay internet o el font no está cacheado.
  await initializeDateFormatting('es', null);
  GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans()]).ignore();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const VexaApp(),
    ),
  );
}
