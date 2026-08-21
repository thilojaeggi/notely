class AnalyticsEvents {
  // Screen views
  static const String screenView = 'screen_view';

  // Authentication
  static const String loginAttempt = 'login_attempt';
  static const String loginSuccess = 'login_success';
  static const String loginFailure = 'login_failure';
  static const String logout = 'logout';
  static const String twoFactorPrompted = 'two_factor_prompted';
  static const String twoFactorCompleted = 'two_factor_completed';

  // Paywall & Monetization
  static const String paywallViewed = 'paywall_viewed';
  static const String paywallPurchased = 'paywall_purchased';
  static const String paywallRestored = 'paywall_restored';
  static const String paywallCancelled = 'paywall_cancelled';
  static const String paywallError = 'paywall_error';
  static const String restorePurchasesStarted = 'restore_purchases_started';
  static const String restorePurchasesSuccess = 'restore_purchases_success';
  static const String restorePurchasesFailed = 'restore_purchases_failed';

  // Homework
  static const String homeworkCreated = 'homework_created';
  static const String homeworkToggled = 'homework_toggled';
  static const String homeworkDeleted = 'homework_deleted';

  // Timetable
  static const String timetableDateSelected = 'timetable_date_selected';
  static const String timetableLessonTapped = 'timetable_lesson_tapped';
  static const String timetableRefreshed = 'timetable_refreshed';

  // Grades
  static const String gradesOverviewViewed = 'grades_overview_viewed';
  static const String gradesSubjectViewed = 'grades_subject_viewed';
  static const String gradesRefreshed = 'grades_refreshed';

  // Absences
  static const String absencesOverviewViewed = 'absences_overview_viewed';
  static const String absencesRefreshed = 'absences_refreshed';

  // Exams
  static const String examsOverviewViewed = 'exams_overview_viewed';
  static const String examTapped = 'exam_tapped';

  // App customization & settings
  static const String themeChanged = 'theme_changed';
  static const String appIconChanged = 'app_icon_changed';
  static const String settingChanged = 'setting_changed';

  // System, Deep links & Widgets
  static const String deepLinkOpened = 'deep_link_opened';
  static const String widgetSyncCompleted = 'widget_sync_completed';
}

class AnalyticsParams {
  static const String source = 'source';
  static const String method = 'method';
  static const String school = 'school';
  static const String reason = 'reason';
  static const String statusCode = 'status_code';
  static const String durationMs = 'duration_ms';
  static const String isAutofill = 'is_autofill';
  static const String packageId = 'package_id';
  static const String offeringId = 'offering_id';
  static const String errorMessage = 'error_message';
  static const String isDone = 'is_done';
  static const String hasDueDate = 'has_due_date';
  static const String subject = 'subject';
  static const String dayOffset = 'day_offset';
  static const String isToday = 'is_today';
  static const String isSubstitute = 'is_substitute';
  static const String isCancelled = 'is_cancelled';
  static const String count = 'count';
  static const String theme = 'theme';
  static const String iconName = 'icon_name';
  static const String settingName = 'setting_name';
  static const String settingValue = 'setting_value';
  static const String target = 'target';
  static const String rawUrl = 'raw_url';
  static const String status = 'status';
  static const String itemCount = 'item_count';
}

class AnalyticsUserProperties {
  static const String school = 'school';
  static const String isPremium = 'is_premium';
  static const String otpAutofillEnabled = 'otp_autofill_enabled';
  static const String themeMode = 'theme_mode';
  static const String appIcon = 'app_icon';
  static const String appVersion = 'app_version';
}

class PaywallSource {
  static const String settingsBanner = 'settings_banner';
  static const String settingsAppIcon = 'settings_app_icon';
  static const String returningUser = 'returning_user';
  static const String deepLink = 'deep_link';
  static const String examsAdRemove = 'exams_ad_remove';
  static const String widgetSync = 'widget_sync';
}

class LoginMethod {
  static const String manual = 'manual';
  static const String autofill = 'autofill';
  static const String cachedToken = 'cached_token';
}
