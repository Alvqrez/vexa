import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-load fonts so the first frame never renders with a missing typeface.
  await Future.wait([
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
