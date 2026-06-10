import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages PIN, password, and account credentials stored securely on-device.
///
/// Credentials are stored in the platform Keychain (iOS) / Keystore (Android)
/// via flutter_secure_storage. Passwords and PINs are hashed with SHA-256 +
/// a per-credential salt before storage — they are never stored in plaintext.
class LocalAuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Key constants ─────────────────────────────────────────────────────────

  static const _accountEmailKey = 'account_email';
  static const _accountHashKey = 'account_password_hash';
  static const _accountSaltKey = 'account_password_salt';

  static const _pinEnabledKey = 'security_pin_enabled';
  static const _pinHashKey = 'security_pin_hash';
  static const _pinSaltKey = 'security_pin_salt';

  static const _passwordEnabledKey = 'security_password_enabled';
  static const _passwordHashKey = 'security_password_hash';
  static const _passwordSaltKey = 'security_password_salt';

  static const _biometricEnabledKey = 'security_biometric_enabled';

  // ── Hashing ───────────────────────────────────────────────────────────────

  /// Generates a cryptographically random 32-character hex salt.
  static String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  /// Returns SHA-256(salt + value) as a hex string.
  static String _hash(String value, String salt) {
    final bytes = utf8.encode('$salt:$value');
    return sha256.convert(bytes).toString();
  }

  // ── Account credentials ───────────────────────────────────────────────────

  static Future<bool> isAccountSetup() async {
    final email = await _storage.read(key: _accountEmailKey);
    return email != null && email.isNotEmpty;
  }

  static Future<String?> getAccountEmail() =>
      _storage.read(key: _accountEmailKey);

  static Future<void> setupAccount(String email, String password) async {
    final salt = _generateSalt();
    await _storage.write(key: _accountEmailKey, value: email);
    await _storage.write(key: _accountSaltKey, value: salt);
    await _storage.write(key: _accountHashKey, value: _hash(password, salt));
  }

  static Future<bool> verifyAccount(String email, String password) async {
    final storedEmail = await _storage.read(key: _accountEmailKey);
    final storedSalt = await _storage.read(key: _accountSaltKey);
    final storedHash = await _storage.read(key: _accountHashKey);

    if (storedEmail == null || storedSalt == null || storedHash == null) {
      return false;
    }
    return storedEmail.toLowerCase() == email.toLowerCase() &&
        _hash(password, storedSalt) == storedHash;
  }

  // ── Lock state ────────────────────────────────────────────────────────────

  static Future<bool> isPinEnabled() async =>
      (await _storage.read(key: _pinEnabledKey)) == 'true';

  static Future<bool> isPasswordEnabled() async =>
      (await _storage.read(key: _passwordEnabledKey)) == 'true';

  static Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _biometricEnabledKey)) == 'true';

  static Future<bool> isAnyLockEnabled() async =>
      await isPinEnabled() ||
      await isPasswordEnabled() ||
      await isBiometricEnabled();

  // ── PIN ───────────────────────────────────────────────────────────────────

  static Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: _hash(pin, salt));
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final stored = await _storage.read(key: _pinHashKey);
    if (salt == null || stored == null) return false;
    return _hash(pin, salt) == stored;
  }

  static Future<void> disablePin() async {
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }

  // ── Password ──────────────────────────────────────────────────────────────

  static Future<void> setPassword(String password) async {
    final salt = _generateSalt();
    await _storage.write(key: _passwordSaltKey, value: salt);
    await _storage.write(key: _passwordHashKey, value: _hash(password, salt));
    await _storage.write(key: _passwordEnabledKey, value: 'true');
  }

  static Future<bool> verifyPassword(String password) async {
    final salt = await _storage.read(key: _passwordSaltKey);
    final stored = await _storage.read(key: _passwordHashKey);
    if (salt == null || stored == null) return false;
    return _hash(password, salt) == stored;
  }

  static Future<void> disablePassword() async {
    await _storage.write(key: _passwordEnabledKey, value: 'false');
  }

  // ── Biometric ─────────────────────────────────────────────────────────────

  static Future<void> setBiometric(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  // ── Reset account ─────────────────────────────────────────────────────────

  /// Deletes all stored credentials. Used by "forgot password" flow.
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _accountEmailKey);
    await _storage.delete(key: _accountHashKey);
    await _storage.delete(key: _accountSaltKey);
  }

  /// Disables all lock methods. Does not delete account credentials.
  static Future<void> clearAll() async {
    await _storage.write(key: _pinEnabledKey, value: 'false');
    await _storage.write(key: _passwordEnabledKey, value: 'false');
    await _storage.write(key: _biometricEnabledKey, value: 'false');
  }

  /// Full wipe: account + all lock data. Used on factory reset.
  static Future<void> wipeAll() async {
    await _storage.deleteAll();
  }
}
