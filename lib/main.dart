import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'core/data/isar_service.dart';
import 'core/data/local_prefs_service.dart';
import 'core/providers/isar_provider.dart';
import 'core/services/notification_service.dart';
import 'core/utils/receipt_image_store.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await initializeDateFormatting('es', null);
  GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans()]).then((_) {
    debugPrint('GoogleFonts loaded successfully');
  }).catchError((e) {
    debugPrint('GoogleFonts load error (non-critical): $e');
  });
  await NotificationService.init();
  await ReceiptImageStore.init();

  runApp(const _AppLoader());
}

// Initializes Isar asynchronously and shows a retry screen on failure.
class _AppLoader extends StatefulWidget {
  const _AppLoader();
  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  Isar? _isar;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (mounted) setState(() { _isar = null; _error = null; });
    try {
      final isar = await openIsar().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Isar tardó demasiado al abrir'),
      );

      // On first release launch, purge any seed data left from debug sessions.
      if (kReleaseMode) {
        const flagKey = 'release_initialized_v1';
        final alreadyDone = await LocalPrefsService.getBool(flagKey);
        if (!alreadyDone) {
          const seedTxIds = ['1', '2', '3', '4', '5', '6', '7'];
          const seedAccountIds = ['1', '2', '3'];
          final hasSeedTx = await isar.isarTransactions
              .filter()
              .anyOf(seedTxIds, (q, id) => q.txIdEqualTo(id))
              .findFirst();
          if (hasSeedTx != null) {
            await isar.writeTxn(() async {
              for (final id in seedTxIds) {
                await isar.isarTransactions.deleteByTxId(id);
              }
              for (final id in seedAccountIds) {
                await isar.isarAccounts.deleteByAccountId(id);
              }
            });
          }
          await LocalPrefsService.setBool(flagKey, true);
        }
      }

      if (mounted) setState(() => _isar = isar);
    } catch (e) {
      debugPrint('_AppLoader._init failed: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isar = _isar;

    if (isar != null) {
      return ProviderScope(
        overrides: [isarProvider.overrideWithValue(isar)],
        child: const VexaApp(),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1117),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFF5F82), size: 48),
                  const SizedBox(height: 20),
                  const Text(
                    'No se pudo iniciar Vexa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Intenta cerrar y reabrir la app.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _init,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D68F),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Loading state
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0F1117),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D68F)),
        ),
      ),
    );
  }
}
