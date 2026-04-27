import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:notely/data/api_client.dart';
import 'package:notely/features/subscription/subscription_manager.dart';
import 'package:notely/models/event.dart';

/// Centralized service for syncing schedule data to the iOS home screen widget.
///
/// Syncs multiple days of lessons so the widget works even when the user
/// doesn't open the app every day. Data is stored in the app-group
/// UserDefaults and read by the WidgetKit extension.
class WidgetSyncService {
  static final WidgetSyncService _instance = WidgetSyncService._internal();
  factory WidgetSyncService() => _instance;
  WidgetSyncService._internal();

  final APIClient _apiClient = APIClient();
  bool _syncing = false;

  /// Fetches events for the next 7 days and syncs them all to the widget.
  /// Call this on app resume or after login to keep the widget fresh.
  Future<void> syncScheduleToWidget() async {
    if (!Platform.isIOS || kIsWeb) return;
    if (_syncing) return;
    if (!SubscriptionManager().isPremium) return;
    _syncing = true;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endDate = today.add(const Duration(days: 6));

      final events = await _apiClient.getEventsForDateRange(today, endDate);

      final Map<String, List<Map<String, String>>> days = {};
      for (final event in events) {
        if (event.startDate == null) continue;
        final dateKey = DateFormat('yyyy-MM-dd').format(event.startDate!);
        days.putIfAbsent(dateKey, () => []);
        days[dateKey]!.add(_lessonDetails(event));
      }

      for (final dayLessons in days.values) {
        dayLessons.sort(
            (a, b) => (a['start'] ?? '').compareTo(b['start'] ?? ''));
      }

      final payload = {
        'lastSynced': now.toUtc().toIso8601String(),
        'days': days,
      };

      await HomeWidget.saveWidgetData<String>(
        'notely_lesson_data',
        jsonEncode(payload),
      );
      await HomeWidget.updateWidget(
        name: 'ScheduleWidget',
        iOSName: 'ScheduleWidget',
      );
    } catch (e) {
      debugPrint('WidgetSyncService: failed to sync – $e');
    } finally {
      _syncing = false;
    }
  }

  /// Quick-sync a single date's events to the widget (for immediate feedback
  /// while the user is on the timetable page). Preserves other days already
  /// stored in the payload and cleans up dates in the past.
  Future<void> syncEventsForDate(List<Event> events, DateTime date) async {
    if (!Platform.isIOS || kIsWeb) return;
    if (!SubscriptionManager().isPremium) return;

    try {
      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      // Read existing widget payload to preserve other days
      final existingJson =
          await HomeWidget.getWidgetData<String>('notely_lesson_data');
      Map<String, dynamic> existingPayload = {};
      if (existingJson != null) {
        try {
          existingPayload =
              jsonDecode(existingJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      final Map<String, dynamic> days = {};
      if (existingPayload['days'] is Map) {
        days.addAll(Map<String, dynamic>.from(existingPayload['days']));
      }

      final sortedEvents = events
          .where((e) => e.startDate != null)
          .toList()
        ..sort((a, b) => a.startDate!.compareTo(b.startDate!));

      days[dateKey] = sortedEvents.map(_lessonDetails).toList();

      // Remove dates older than yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);
      days.removeWhere((key, _) => key.compareTo(yesterdayKey) < 0);

      final payload = {
        'lastSynced': now.toUtc().toIso8601String(),
        'days': days,
      };

      await HomeWidget.saveWidgetData<String>(
        'notely_lesson_data',
        jsonEncode(payload),
      );
      await HomeWidget.updateWidget(
        name: 'ScheduleWidget',
        iOSName: 'ScheduleWidget',
      );
    } catch (e) {
      debugPrint('WidgetSyncService: failed to sync date – $e');
    }
  }

  Map<String, String> _lessonDetails(Event event) {
    final lessonName = (event.courseName?.trim().isNotEmpty ?? false)
        ? event.courseName!
        : (event.text ?? '');
    final teacher = (event.teachers != null && event.teachers!.isNotEmpty)
        ? event.teachers!.first
        : '';
    final room = event.roomToken ?? '';
    final time = (event.startDate != null)
        ? DateFormat('HH:mm').format(event.startDate!)
        : '';
    final start = event.startDate?.toUtc().toIso8601String() ?? '';
    final end = event.endDate?.toUtc().toIso8601String() ?? '';

    return {
      'lessonName': lessonName,
      'room': room,
      'teacher': teacher,
      'time': time,
      'start': start,
      'end': end,
    };
  }
}
