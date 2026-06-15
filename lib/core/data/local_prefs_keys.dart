/// Centralized registry of all LocalPrefs keys used in the app.
///
/// Use these constants instead of inline string literals to prevent
/// collisions, typos, and aid future migration audits.
abstract final class LocalPrefsKeys {
  // ── App lifecycle ────────────────────────────────────────────────────────────
  static const onboardingDone = 'onboarding_done';
  static const tutorialShown = 'tutorial_shown';
  static const releaseInitializedV1 = 'release_initialized_v1';

  // ── Theme / appearance ───────────────────────────────────────────────────────
  static const themeMode = 'theme_mode';
  static const settingsHaptics = 'settings_haptics';
  static const settingsAnimations = 'settings_animations';
  static const settingsHideAmounts = 'settings_hide_amounts';
  static const settingsAnalytics = 'settings_analytics';

  // ── Currency ─────────────────────────────────────────────────────────────────
  static const currencySymbol = 'currency_symbol';
  static const currencyCode = 'currency_code';

  // ── Profile ──────────────────────────────────────────────────────────────────
  static const profileName = 'profile_name';
  static const profileEmail = 'profile_email';
  static const profilePhone = 'profile_phone';
  static const profileBirthdate = 'profile_birthdate';
  static const profilePhotoPath = 'profile_photo_path';

  // ── Accounts ─────────────────────────────────────────────────────────────────
  static const lastAccountId = 'last_account_id';
  /// Per-account savings flag: append account ID → e.g. `account_savings_<id>`
  static const accountSavingsPrefix = 'account_savings_';

  // ── Loans ────────────────────────────────────────────────────────────────────
  /// Per-loan origin transaction: append loan ID → e.g. `loan_origin_tx_<id>`
  static const loanOriginTxPrefix = 'loan_origin_tx_';
  static const loansOnboardingSeen = 'loans_onboarding_seen';

  // ── Gamification / streak ────────────────────────────────────────────────────
  static const streakCurrent = 'streak_current';
  static const streakLongest = 'streak_longest';
  static const streakLastActive = 'streak_last_active';
  static const streakLastTx = 'streak_last_tx';

  // ── Vexa Score ───────────────────────────────────────────────────────────────
  static const vexaScoreHistory = 'vexa_score_history';

  // ── Notifications ────────────────────────────────────────────────────────────
  static const notifDailyTip = 'notif_daily_tip';
  static const notifPrediction = 'notif_prediction';
  static const notifTransactions = 'notif_transactions';
  static const notifBudgetAlerts = 'notif_budget_alerts';
  static const notifWeeklySummary = 'notif_weekly_summary';
  static const notifMarketing = 'notif_marketing';
  static const notifSecurity = 'notif_security';
  static const notifClearedDay = 'notif_cleared_day';
  static const lastAlertDay = 'last_alert_day';

  // ── Subscriptions ────────────────────────────────────────────────────────────
  static const subsLastProcessedDate = 'subs_last_processed_date';

  // ── Onboarding / explainers ──────────────────────────────────────────────────
  static const savingsExplained = 'savings_explained';
}
