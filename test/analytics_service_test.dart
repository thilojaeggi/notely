import 'package:flutter_test/flutter_test.dart';
import 'package:notely/core/analytics/analytics_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Constants Test', () {
    test('Event names are properly formatted', () {
      expect(AnalyticsEvents.loginAttempt, 'login_attempt');
      expect(AnalyticsEvents.loginSuccess, 'login_success');
      expect(AnalyticsEvents.loginFailure, 'login_failure');
      expect(AnalyticsEvents.paywallViewed, 'paywall_viewed');
      expect(AnalyticsEvents.paywallPurchased, 'paywall_purchased');
      expect(AnalyticsEvents.homeworkCreated, 'homework_created');
      expect(AnalyticsEvents.timetableDateSelected, 'timetable_date_selected');
      expect(AnalyticsEvents.gradesOverviewViewed, 'grades_overview_viewed');
      expect(AnalyticsEvents.absencesOverviewViewed, 'absences_overview_viewed');
      expect(AnalyticsEvents.examsOverviewViewed, 'exams_overview_viewed');
      expect(AnalyticsEvents.appIconChanged, 'app_icon_changed');
    });

    test('User properties keys are properly formatted', () {
      expect(AnalyticsUserProperties.school, 'school');
      expect(AnalyticsUserProperties.isPremium, 'is_premium');
      expect(AnalyticsUserProperties.otpAutofillEnabled, 'otp_autofill_enabled');
      expect(AnalyticsUserProperties.themeMode, 'theme_mode');
      expect(AnalyticsUserProperties.appIcon, 'app_icon');
    });

    test('Paywall sources are properly defined', () {
      expect(PaywallSource.settingsBanner, 'settings_banner');
      expect(PaywallSource.settingsAppIcon, 'settings_app_icon');
      expect(PaywallSource.returningUser, 'returning_user');
      expect(PaywallSource.deepLink, 'deep_link');
    });
  });
}
