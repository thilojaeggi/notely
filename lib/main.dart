import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:universal_io/universal_io.dart' show Platform;

import 'package:notely/app.dart';
import 'package:notely/firebase_options.dart';
import 'package:notely/data/database/homework_database.dart';
import 'package:notely/features/notifications/notification_service.dart';
import 'package:notely/features/subscription/subscription_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    HomeWidget.setAppGroupId('group.ch.thilojaeggi.notely');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  if (!kIsWeb) {
    await HomeworkDatabase.instance.database;
    await NotificationService.checkNotifications(messaging);
  }

  await SubscriptionManager().initialize();
  await analytics.setAnalyticsCollectionEnabled(true);
  runApp(const NotelyApp());
}
