import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_prefs_service.dart';

/// Global toggle: when false, all UI animations are disabled (reduced motion).
final animationsEnabledProvider = StateProvider<bool>((ref) => true);

/// When true, sensitive monetary values are hidden behind asterisks.
final hideAmountsProvider = StateProvider<bool>((ref) => false);

/// Currently selected currency symbol.
final currencySymbolProvider = StateProvider<String>((ref) => '\$');

/// App theme mode: dark, light, or follow system.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

// ── User profile ──────────────────────────────────────────────────────────────

class UserProfile {
  const UserProfile({this.name = '', this.email = '', this.phone = '', this.birthdate = ''});
  final String name;
  final String email;
  final String phone;
  final String birthdate;

  String get firstName {
    final n = name.trim();
    return n.isEmpty ? '' : n.split(' ').first;
  }

  String get initial {
    final n = name.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  UserProfile copyWith({String? name, String? email, String? phone, String? birthdate}) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        birthdate: birthdate ?? this.birthdate,
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
    state = UserProfile(name: name, email: email, phone: phone, birthdate: birthdate);
  }

  Future<void> update({String? name, String? email, String? phone, String? birthdate}) async {
    state = state.copyWith(name: name, email: email, phone: phone, birthdate: birthdate);
    if (name != null) await LocalPrefsService.setString('profile_name', name);
    if (email != null) await LocalPrefsService.setString('profile_email', email);
    if (phone != null) await LocalPrefsService.setString('profile_phone', phone);
    if (birthdate != null) await LocalPrefsService.setString('profile_birthdate', birthdate);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(),
);
