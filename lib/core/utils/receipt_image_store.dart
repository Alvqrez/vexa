import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Almacena las fotos adjuntas a transacciones (recibos, tickets, facturas)
/// dentro del directorio de documentos de la app, en `receipts/`.
///
/// En la base de datos se guarda solo el NOMBRE de archivo — nunca la ruta
/// absoluta — porque en iOS el contenedor cambia entre actualizaciones.
class ReceiptImageStore {
  static Directory? _dir;

  /// Llamar una vez al arrancar la app (idempotente).
  static Future<void> init() async {
    if (_dir != null) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}${Platform.pathSeparator}receipts');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _dir = dir;
    } catch (e) {
      debugPrint('ReceiptImageStore.init error: $e');
    }
  }

  static bool get isReady => _dir != null;

  /// Ruta absoluta para mostrar una imagen guardada. Null si no está lista
  /// la inicialización o el archivo ya no existe.
  static String? resolve(String fileName) {
    final dir = _dir;
    if (dir == null) return null;
    final path = '${dir.path}${Platform.pathSeparator}$fileName';
    return File(path).existsSync() ? path : null;
  }

  /// Copia la imagen elegida al almacén y devuelve su nombre de archivo.
  static Future<String?> persist(XFile picked) async {
    await init();
    final dir = _dir;
    if (dir == null) return null;
    try {
      final ext = picked.path.contains('.')
          ? picked.path.substring(picked.path.lastIndexOf('.'))
          : '.jpg';
      final name = '${const Uuid().v4()}$ext';
      await File(picked.path)
          .copy('${dir.path}${Platform.pathSeparator}$name');
      return name;
    } catch (e) {
      debugPrint('ReceiptImageStore.persist error: $e');
      return null;
    }
  }

  static Future<void> delete(String fileName) async {
    final path = resolve(fileName);
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (e) {
      debugPrint('ReceiptImageStore.delete error: $e');
    }
  }

  static Future<void> deleteAll(Iterable<String> fileNames) async {
    for (final name in fileNames) {
      await delete(name);
    }
  }
}
