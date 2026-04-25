import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notely/data/api_client.dart';
import 'package:notely/models/grade.dart';
import 'package:notely/features/auth/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notely/firebase_options.dart';

class NotificationService {
  static late AndroidNotificationChannel channel;
  static bool isFlutterLocalNotificationsInitialized = false;
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }
    channel = const AndroidNotificationChannel(
      'newGradeNotification', // id
      'Benachrichtigung bei neuer Note.', // title
      description:
          'Wenn eine neue Note eingetragen wird, erhältst du eine Benachrichtigung.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getToken().then((value) {
      debugPrint(value);
    });
    isFlutterLocalNotificationsInitialized = true;
  }

  static Future<void> checkNotifications(FirebaseMessaging messaging) async {
    debugPrint("Checking notifications");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? notificationsEnabled = prefs.getBool("notificationsEnabled");
    FirebaseMessaging.onBackgroundMessage(backgroundHandler);
    if (!kIsWeb) {
      await setupFlutterNotifications();
    }
    if (notificationsEnabled == null || notificationsEnabled) {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("Notifications are enabled");
        messaging.subscribeToTopic("all");
        messaging.subscribeToTopic("newGradeNotification");
        await prefs.setBool("notificationsEnabled", true);
      } else if (notificationsEnabled == null ||
          settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("Notifications are disabled");
        try {
          messaging.unsubscribeFromTopic("all");
          messaging.unsubscribeFromTopic("newGradeNotification");
        } catch (e) {
          debugPrint(e.toString());
        }
        await prefs.setBool("notificationsEnabled", false);
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    final APIClient client = APIClient();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    !kIsWeb ? await setupFlutterNotifications() : null;
    debugPrint('Handling a background message ${message.messageId}');
    if (message.contentAvailable ||
        message.from == "/topics/newGradeNotification") {
      final prefs = await SharedPreferences.getInstance();
      final school = (prefs.getString("school") ?? "ksso").toLowerCase();
      if (school.isEmpty) return;

      bool hasValidToken = false;
      final tokenManager = TokenManager();
      final accessToken = await tokenManager.getValidAccessToken(school);
      if (accessToken != null && accessToken.isNotEmpty) {
        client.accessToken = accessToken;
        hasValidToken = true;
      }

      if (!hasValidToken) return;
      client.school = school;
      try {
        List<Grade> oldGrades = await client.getGrades(true);
        List<Grade> newGrades = await client.getGrades(false);

        if (newGrades.length <= oldGrades.length || oldGrades.isEmpty) return;

        // Get grades that are in newGrades but not in oldGrades, not using contains cause it doesn't work -.-
        newGrades = newGrades.where((element) {
          return !oldGrades.any((oldGrade) => oldGrade.id == element.id);
        }).toList();

        for (Grade grade in newGrades) {
          // send notification
          flutterLocalNotificationsPlugin.show(
            grade.id.hashCode,
            "Notely",
            "Du hast eine neue ${grade.subject} Note.",
            NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: 'ic_stat_school',
                  playSound: true,
                  enableVibration: true,
                  importance: Importance.high,
                  priority: Priority.high,
                  visibility: NotificationVisibility.public,
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                )),
          );
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }
}
