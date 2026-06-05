import 'dart:convert';
import '../data/local_prefs_service.dart';

/// Manages local PIN, password, and account authentication stored on-device.
class LocalAuthService {
  static const _pinEnabledKey = 'security_pin_enabled';
  static const _pinHashKey = 'security_pin_hash';
  static const _passwordEnabledKey = 'security_password_enabled';
  static const _passwordHashKey = 'security_password_hash';
  static const _biometricEnabledKey = 'security_biometric_enabled';

  // ── Account credentials (login page) ─────────────────────────────────────────

  static const _accountEmailKey = 'account_email';
  static const _accountPasswordHashKey = 'account_password_hash';

  static Future<bool> isAccountSetup() async =>
      (await LocalPrefsService.getString(_accountEmailKey)) != null;

  static Future<String?> getAccountEmail() =>
      LocalPrefsService.getString(_accountEmailKey);

  static Future<void> setupAccount(String email, String password) async {
    await LocalPrefsService.setString(_accountEmailKey, email);
    await LocalPrefsService.setString(
        _accountPasswordHashKey, _encode(password));
  }

  static Future<bool> verifyAccount(String email, String password) async {
    final storedEmail =
        await LocalPrefsService.getString(_accountEmailKey);
    final storedHash =
        await LocalPrefsService.getString(_accountPasswordHashKey);
    return storedEmail != null &&
        storedEmail.toLowerCase() == email.toLowerCase() &&
        storedHash == _encode(password);
  }

  // ── Query state ─────────────────────────────────────────────────────────────

  static Future<bool> isPinEnabled() =>
      LocalPrefsService.getBool(_pinEnabledKey);

  static Future<bool> isPasswordEnabled() =>
      LocalPrefsService.getBool(_passwordEnabledKey);

  static Future<bool> isBiometricEnabled() =>
      LocalPrefsService.getBool(_biometricEnabledKey);

  static Future<bool> isAnyLockEnabled() async =>
      await isPinEnabled() || await isPasswordEnabled();

  // ── PIN ─────────────────────────────────────────────────────────────────────

  static Future<void> setPin(String pin) async {
    await LocalPrefsService.setString(_pinHashKey, _encode(pin));
    await LocalPrefsService.setBool(_pinEnabledKey, true);
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await LocalPrefsService.getString(_pinHashKey);
    return stored != null && stored == _encode(pin);
  }

  static Future<void> disablePin() async {
    await LocalPrefsService.setBool(_pinEnabledKey, false);
  }

  // ── Password ─────────────────────────────────────────────────────────────────

  static Future<void> setPassword(String password) async {
    await LocalPrefsService.setString(_passwordHashKey, _encode(password));
    await LocalPrefsService.setBool(_passwordEnabledKey, true);
  }

  static Future<bool> verifyPassword(String password) async {
    final stored = await LocalPrefsService.getString(_passwordHashKey);
    return stored != null && stored == _encode(password);
  }

  static Future<void> disablePassword() async {
    await LocalPrefsService.setBool(_passwordEnabledKey, false);
  }

  // ── Biometric ────────────────────────────────────────────────────────────────

  static Future<void> setBiometric(bool enabled) =>
      LocalPrefsService.setBool(_biometricEnabledKey, enabled);

  // ── Clear all ────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await LocalPrefsService.setBool(_pinEnabledKey, false);
    await LocalPrefsService.setBool(_passwordEnabledKey, false);
    await LocalPrefsService.setBool(_biometricEnabledKey, false);
  }

  // ── Internal encoding (not cryptographic, just avoids plaintext) ─────────────

  static String _encode(String value) =>
      base64Encode(utf8.encode(value.split('').reversed.join()));
}
