import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    // Pre-load Spanish locale data for all DateFormat('...', 'es') calls.
    initializeDateFormatting('es', null),
    // Pre-load fonts so the first frame never renders with a missing typeface.
    GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
    ]),
  ]);
  runApp(
    const ProviderScope(
      child: VexaApp(),
    ),
  );
}
