import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../data/local_prefs_service.dart';

/// Global toggle: when false, all UI animations are disabled (reduced motion).
final animationsEnabledProvider = StateProvider<bool>((ref) => true);

/// When true, sensitive monetary values are hidden behind asterisks.
final hideAmountsProvider = StateProvider<bool>((ref) => false);

/// Currently selected currency symbol.
final currencySymbolProvider = StateProvider<String>((ref) => '\$');

/// Currently selected currency code (e.g. 'USD', 'EUR').
final currencyCodeProvider = StateProvider<String>((ref) => 'USD');

/// App theme mode: dark, light, or follow system.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

// ── User profile ──────────────────────────────────────────────────────────────

class UserProfile {
  const UserProfile({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.birthdate = '',
    this.photoPath,
  });
  final String name;
  final String email;
  final String phone;
  final String birthdate;
  final String? photoPath;

  String get firstName {
    final n = name.trim();
    return n.isEmpty ? '' : n.split(' ').first;
  }

  String get initial {
    final n = name.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? birthdate,
    String? photoPath,
    bool clearPhoto = false,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        birthdate: birthdate ?? this.birthdate,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      );
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile()) {
    _load();
  }

  Future<void> _load() async {
    final name = await LocalPrefsService.getString('profile_name') ?? '';
    final email = await LocalPrefsService.getString('profile_email') ?? '';
    final phone = await LocalPrefsService.getString('profile_phone') ?? '';
    final birthdate = await LocalPrefsService.getString('profile_birthdate') ?? '';
    String? photoPath = await LocalPrefsService.getString('profile_photo_path');

    // Validate stored path; fall back to the standard filename if the path is
    // stale (e.g. after a reinstall or documents-dir change).
    if (photoPath == null || !File(photoPath).existsSync()) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final standard = File('${dir.path}/profile_photo.jpg');
        if (standard.existsSync()) {
          photoPath = standard.path;
          await LocalPrefsService.setString('profile_photo_path', photoPath);
        } else {
          photoPath = null;
        }
      } catch (_) {
        photoPath = null;
      }
    }

    state = UserProfile(
        name: name, email: email, phone: phone, birthdate: birthdate, photoPath: photoPath);
  }

  void clearProfile() {
    state = const UserProfile();
  }

  Future<void> update({
    String? name,
    String? email,
    String? phone,
    String? birthdate,
    String? photoPath,
  }) async {
    state = state.copyWith(
        name: name, email: email, phone: phone, birthdate: birthdate, photoPath: photoPath);
    if (name != null) await LocalPrefsService.setString('profile_name', name);
    if (email != null) await LocalPrefsService.setString('profile_email', email);
    if (phone != null) await LocalPrefsService.setString('profile_phone', phone);
    if (birthdate != null) await LocalPrefsService.setString('profile_birthdate', birthdate);
    if (photoPath != null) await LocalPrefsService.setString('profile_photo_path', photoPath);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(),
);

// ── Notification preferences ──────────────────────────────────────────────────

class NotifPrefs {
  const NotifPrefs({
    this.dailyTip = true,
    this.prediction = true,
  });
  final bool dailyTip;
  final bool prediction;
}

class NotifPrefsNotifier extends StateNotifier<NotifPrefs> {
  NotifPrefsNotifier() : super(const NotifPrefs()) {
    _load();
  }

  Future<void> _load() async {
    final dailyTip =
        await LocalPrefsService.getBool('notif_daily_tip', defaultValue: true);
    final prediction = await LocalPrefsService.getBool('notif_prediction',
        defaultValue: true);
    state = NotifPrefs(dailyTip: dailyTip, prediction: prediction);
  }

  void reload() => _load();
}

final notifPrefsProvider =
    StateNotifierProvider<NotifPrefsNotifier, NotifPrefs>(
  (ref) => NotifPrefsNotifier(),
);
