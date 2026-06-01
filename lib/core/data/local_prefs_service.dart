import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Simple synchronous-friendly key-value store backed by a JSON file.
/// Uses an in-memory cache so repeated reads don't hit disk.
class LocalPrefsService {
  static Map<String, dynamic>? _cache;

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/vexa_prefs.json');
  }

  static Future<Map<String, dynamic>> _read() async {
    if (_cache != null) return _cache!;
    try {
      final file = await _getFile();
      if (!file.existsSync()) return _cache = {};
      final content = await file.readAsString();
      return _cache = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return _cache = {};
    }
  }

  static Future<void> _flush() async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(_cache));
    } catch (_) {}
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final data = await _read();
    return data[key] as bool? ?? defaultValue;
  }

  static Future<void> setBool(String key, bool value) async {
    await _read();
    _cache![key] = value;
    await _flush();
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final data = await _read();
    return data[key] as int? ?? defaultValue;
  }

  static Future<void> setInt(String key, int value) async {
    await _read();
    _cache![key] = value;
    await _flush();
  }

  static Future<String?> getString(String key) async {
    final data = await _read();
    return data[key] as String?;
  }

  static Future<void> setString(String key, String value) async {
    await _read();
    _cache![key] = value;
    await _flush();
  }
}
