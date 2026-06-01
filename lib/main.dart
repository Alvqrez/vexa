import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/data/isar_service.dart';
import 'core/providers/isar_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isar = await openIsar();

  await Future.wait([
    initializeDateFormatting('es', null),
    GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans()]),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const VexaApp(),
    ),
  );
}
