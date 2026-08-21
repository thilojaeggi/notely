import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:notely/core/analytics/analytics_constants.dart';

/// Centralized analytics service for Notely.
///
/// Wraps [FirebaseAnalytics] with strongly-typed methods, safe error handling,
/// and debug logging. All calls are safe to execute across all platforms and
/// will never throw an exception to caller code.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs a custom event safely with optional parameters and debug printing.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      final sanitizedParams = _sanitizeParameters(parameters);
      if (kDebugMode) {
        debugPrint('[Analytics] 📊 Event: $name | Params: $sanitizedParams');
      }
      await _analytics.logEvent(
        name: name,
        parameters: sanitizedParams,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to log event $name: $e');
      }
    }
  }

  // ==========================================
  // Screen Views
  // ==========================================

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[Analytics] 📱 Screen: $screenName');
      }
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to log screen view: $e');
      }
    }
  }

  // ==========================================
  // User Properties & Identity
  // ==========================================

  Future<void> setSchool(String? school) async {
    try {
      final value = school?.trim().toLowerCase();
      if (kDebugMode) {
        debugPrint('[Analytics] 👤 UserProperty: school = $value');
      }
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.school,
        value: value,
      );
      if (value != null && value.isNotEmpty) {
        await _analytics.setDefaultEventParameters({'school': value});
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to set school: $e');
      }
    }
  }

  Future<void> setPremium(bool isPremium) async {
    try {
      final value = isPremium ? 'true' : 'false';
      if (kDebugMode) {
        debugPrint('[Analytics] 👤 UserProperty: is_premium = $value');
      }
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.isPremium,
        value: value,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to set is_premium: $e');
      }
    }
  }

  Future<void> setOtpAutofillEnabled(bool enabled) async {
    try {
      final value = enabled ? 'true' : 'false';
      if (kDebugMode) {
        debugPrint('[Analytics] 👤 UserProperty: otp_autofill_enabled = $value');
      }
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.otpAutofillEnabled,
        value: value,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to set otp_autofill_enabled: $e');
      }
    }
  }

  Future<void> setThemeMode(String theme) async {
    try {
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.themeMode,
        value: theme,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to set theme_mode: $e');
      }
    }
  }

  Future<void> setAppIcon(String iconName) async {
    try {
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.appIcon,
        value: iconName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to set app_icon: $e');
      }
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to set userId: $e');
      }
    }
  }

  /// Clears user properties and identity upon logout.
  Future<void> clearUserData() async {
    try {
      if (kDebugMode) {
        debugPrint('[Analytics] 🧹 Clearing user analytics data');
      }
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.otpAutofillEnabled,
        value: null,
      );
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.school,
        value: null,
      );
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.isPremium,
        value: null,
      );
      await _analytics.setUserProperty(
        name: AnalyticsUserProperties.appIcon,
        value: null,
      );
      await _analytics.setUserId(id: null);
      await _analytics.setDefaultEventParameters(null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] ⚠️ Failed to clear analytics properties: $e');
      }
    }
  }

  // ==========================================
  // Authentication Events
  // ==========================================

  Future<void> logLoginAttempt({
    required String method,
    String? school,
  }) async {
    await logEvent(
      name: AnalyticsEvents.loginAttempt,
      parameters: {
        AnalyticsParams.method: method,
        if (school != null && school.isNotEmpty) AnalyticsParams.school: school,
      },
    );
  }

  Future<void> logLoginSuccess({
    required String method,
    String? school,
    int? durationMs,
    bool? isAutofill,
  }) async {
    await logEvent(
      name: AnalyticsEvents.loginSuccess,
      parameters: {
        AnalyticsParams.method: method,
        if (school != null && school.isNotEmpty) AnalyticsParams.school: school,
        if (durationMs != null) AnalyticsParams.durationMs: durationMs,
        if (isAutofill != null) AnalyticsParams.isAutofill: isAutofill ? 1 : 0,
      },
    );
  }

  Future<void> logLoginFailure({
    required String method,
    String? school,
    required String reason,
    int? statusCode,
  }) async {
    await logEvent(
      name: AnalyticsEvents.loginFailure,
      parameters: {
        AnalyticsParams.method: method,
        AnalyticsParams.reason: _truncate(reason, 100),
        if (school != null && school.isNotEmpty) AnalyticsParams.school: school,
        if (statusCode != null) AnalyticsParams.statusCode: statusCode,
      },
    );
  }

  Future<void> logLogout() async {
    await logEvent(name: AnalyticsEvents.logout);
  }

  Future<void> logTwoFactorPrompted({String? school}) async {
    await logEvent(
      name: AnalyticsEvents.twoFactorPrompted,
      parameters: {
        if (school != null && school.isNotEmpty) AnalyticsParams.school: school,
      },
    );
  }

  Future<void> logTwoFactorCompleted({
    String? school,
    bool? isSuccess,
  }) async {
    await logEvent(
      name: AnalyticsEvents.twoFactorCompleted,
      parameters: {
        if (school != null && school.isNotEmpty) AnalyticsParams.school: school,
        if (isSuccess != null) AnalyticsParams.status: isSuccess ? 'success' : 'failure',
      },
    );
  }

  // ==========================================
  // Paywall & Monetization Events
  // ==========================================

  Future<void> logPaywallViewed({required String source}) async {
    await logEvent(
      name: AnalyticsEvents.paywallViewed,
      parameters: {
        AnalyticsParams.source: source,
      },
    );
  }

  Future<void> logPaywallPurchased({
    String? packageId,
    String? offeringId,
    String? source,
  }) async {
    await logEvent(
      name: AnalyticsEvents.paywallPurchased,
      parameters: {
        if (packageId != null) AnalyticsParams.packageId: packageId,
        if (offeringId != null) AnalyticsParams.offeringId: offeringId,
        if (source != null) AnalyticsParams.source: source,
      },
    );
  }

  Future<void> logPaywallRestored({String? source}) async {
    await logEvent(
      name: AnalyticsEvents.paywallRestored,
      parameters: {
        if (source != null) AnalyticsParams.source: source,
      },
    );
  }

  Future<void> logPaywallCancelled({String? source}) async {
    await logEvent(
      name: AnalyticsEvents.paywallCancelled,
      parameters: {
        if (source != null) AnalyticsParams.source: source,
      },
    );
  }

  Future<void> logPaywallError({
    String? error,
    String? source,
  }) async {
    await logEvent(
      name: AnalyticsEvents.paywallError,
      parameters: {
        if (error != null) AnalyticsParams.errorMessage: _truncate(error, 100),
        if (source != null) AnalyticsParams.source: source,
      },
    );
  }

  Future<void> logRestorePurchasesStarted() async {
    await logEvent(name: AnalyticsEvents.restorePurchasesStarted);
  }

  Future<void> logRestorePurchasesSuccess() async {
    await logEvent(name: AnalyticsEvents.restorePurchasesSuccess);
  }

  Future<void> logRestorePurchasesFailed({String? error}) async {
    await logEvent(
      name: AnalyticsEvents.restorePurchasesFailed,
      parameters: {
        if (error != null) AnalyticsParams.errorMessage: _truncate(error, 100),
      },
    );
  }

  // ==========================================
  // Homework Events
  // ==========================================

  Future<void> logHomeworkCreated({
    String? subject,
    bool hasDueDate = false,
  }) async {
    await logEvent(
      name: AnalyticsEvents.homeworkCreated,
      parameters: {
        if (subject != null && subject.isNotEmpty)
          AnalyticsParams.subject: _sanitizeSubject(subject),
        AnalyticsParams.hasDueDate: hasDueDate ? 1 : 0,
      },
    );
  }

  Future<void> logHomeworkToggled({
    required bool isDone,
    String? subject,
  }) async {
    await logEvent(
      name: AnalyticsEvents.homeworkToggled,
      parameters: {
        AnalyticsParams.isDone: isDone ? 1 : 0,
        if (subject != null && subject.isNotEmpty)
          AnalyticsParams.subject: _sanitizeSubject(subject),
      },
    );
  }

  Future<void> logHomeworkDeleted({String? subject}) async {
    await logEvent(
      name: AnalyticsEvents.homeworkDeleted,
      parameters: {
        if (subject != null && subject.isNotEmpty)
          AnalyticsParams.subject: _sanitizeSubject(subject),
      },
    );
  }

  // ==========================================
  // Timetable Events
  // ==========================================

  Future<void> logTimetableDateSelected({
    required int dayOffset,
    required bool isToday,
  }) async {
    await logEvent(
      name: AnalyticsEvents.timetableDateSelected,
      parameters: {
        AnalyticsParams.dayOffset: dayOffset,
        AnalyticsParams.isToday: isToday ? 1 : 0,
      },
    );
  }

  Future<void> logTimetableLessonTapped({
    String? subject,
    bool? isSubstitute,
    bool? isCancelled,
  }) async {
    await logEvent(
      name: AnalyticsEvents.timetableLessonTapped,
      parameters: {
        if (subject != null && subject.isNotEmpty)
          AnalyticsParams.subject: _sanitizeSubject(subject),
        if (isSubstitute != null)
          AnalyticsParams.isSubstitute: isSubstitute ? 1 : 0,
        if (isCancelled != null)
          AnalyticsParams.isCancelled: isCancelled ? 1 : 0,
      },
    );
  }

  Future<void> logTimetableRefreshed() async {
    await logEvent(name: AnalyticsEvents.timetableRefreshed);
  }

  // ==========================================
  // Grades Events
  // ==========================================

  Future<void> logGradesOverviewViewed() async {
    await logEvent(name: AnalyticsEvents.gradesOverviewViewed);
  }

  Future<void> logGradesSubjectViewed({required String subject}) async {
    await logEvent(
      name: AnalyticsEvents.gradesSubjectViewed,
      parameters: {
        AnalyticsParams.subject: _sanitizeSubject(subject),
      },
    );
  }

  Future<void> logGradesRefreshed() async {
    await logEvent(name: AnalyticsEvents.gradesRefreshed);
  }

  // ==========================================
  // Absences Events
  // ==========================================

  Future<void> logAbsencesOverviewViewed() async {
    await logEvent(name: AnalyticsEvents.absencesOverviewViewed);
  }

  Future<void> logAbsencesRefreshed() async {
    await logEvent(name: AnalyticsEvents.absencesRefreshed);
  }

  // ==========================================
  // Exams Events
  // ==========================================

  Future<void> logExamsOverviewViewed({int? count}) async {
    await logEvent(
      name: AnalyticsEvents.examsOverviewViewed,
      parameters: {
        if (count != null) AnalyticsParams.count: count,
      },
    );
  }

  Future<void> logExamTapped({String? subject}) async {
    await logEvent(
      name: AnalyticsEvents.examTapped,
      parameters: {
        if (subject != null && subject.isNotEmpty)
          AnalyticsParams.subject: _sanitizeSubject(subject),
      },
    );
  }

  // ==========================================
  // App Customization & Settings
  // ==========================================

  Future<void> logThemeChanged(String theme) async {
    await setThemeMode(theme);
    await logEvent(
      name: AnalyticsEvents.themeChanged,
      parameters: {
        AnalyticsParams.theme: theme,
      },
    );
  }

  Future<void> logAppIconChanged(String iconName) async {
    await setAppIcon(iconName);
    await logEvent(
      name: AnalyticsEvents.appIconChanged,
      parameters: {
        AnalyticsParams.iconName: iconName,
      },
    );
  }

  Future<void> logSettingChanged({
    required String settingName,
    required dynamic value,
  }) async {
    await logEvent(
      name: AnalyticsEvents.settingChanged,
      parameters: {
        AnalyticsParams.settingName: settingName,
        AnalyticsParams.settingValue: _truncate(value.toString(), 50),
      },
    );
  }

  // ==========================================
  // Deep Links & Widgets
  // ==========================================

  Future<void> logDeepLinkOpened({
    required String target,
    required String rawUrl,
  }) async {
    await logEvent(
      name: AnalyticsEvents.deepLinkOpened,
      parameters: {
        AnalyticsParams.target: target,
        AnalyticsParams.rawUrl: _truncate(rawUrl, 100),
      },
    );
  }

  Future<void> logWidgetSyncCompleted({
    required String status,
    int? itemCount,
    String? error,
  }) async {
    await logEvent(
      name: AnalyticsEvents.widgetSyncCompleted,
      parameters: {
        AnalyticsParams.status: status,
        if (itemCount != null) AnalyticsParams.itemCount: itemCount,
        if (error != null) AnalyticsParams.errorMessage: _truncate(error, 100),
      },
    );
  }

  // ==========================================
  // Helpers
  // ==========================================

  Map<String, Object>? _sanitizeParameters(Map<String, Object>? params) {
    if (params == null) return null;
    final Map<String, Object> sanitized = {};
    for (final entry in params.entries) {
      final key = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final val = entry.value;
      if (val is String) {
        sanitized[key] = _truncate(val, 100);
      } else if (val is num) {
        sanitized[key] = val;
      } else if (val is bool) {
        sanitized[key] = val ? 1 : 0;
      } else {
        sanitized[key] = _truncate(val.toString(), 100);
      }
    }
    return sanitized;
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength);
  }

  String _sanitizeSubject(String subject) {
    return _truncate(subject.trim(), 40);
  }
}
