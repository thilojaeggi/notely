import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:home_widget/home_widget.dart';
import 'package:notely/core/config/app_config.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionManager {
  static const String _apiKey = AppConfig.appleAPIKey;
  static const String _entitlementId = AppConfig.entitlementId;
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  bool _isInitialized = false;
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      
      _isPremium = await isSubscribed();
      _setPremiumUserProperty(_isPremium);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _isPremium = customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
        _setPremiumUserProperty(_isPremium);
        _syncPremiumToWidget(_isPremium);
      });

      await _syncPremiumToWidget(_isPremium);

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize services: $e');
    }
  }

  void _setPremiumUserProperty(bool isPremium) {
    FirebaseAnalytics.instance.setUserProperty(
      name: 'is_premium',
      value: isPremium ? 'true' : 'false',
    );
  }

  Future<void> _syncPremiumToWidget(bool isPremium) async {
    try {
      // Write as string to avoid Dart bool → NSNumber bridging issues
      await HomeWidget.saveWidgetData<String>('is_premium', isPremium ? 'true' : 'false');
      await HomeWidget.updateWidget(
        name: 'ScheduleWidget',
        iOSName: 'ScheduleWidget',
      );
    } catch (e) {
      // ignore – widget may not be installed
    }
  }

  Future<bool> isSubscribed() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _isPremium = customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      return _isPremium;
    } catch (e) {
      print('Failed to check subscription status: $e');
      return false;
    }
  }

  Future<bool> presentNotelyPremiumPaywall() async {
    try {
      await initialize();
      isSubscribed();
      final Offerings offerings = await Purchases.getOfferings();

      Offering? targetOffering = offerings.all['Notely Premium'];
      targetOffering ??= offerings.current;
      if (targetOffering == null && offerings.all.values.isNotEmpty) {
        targetOffering = offerings.all.values.first;
      }

      if (targetOffering == null) {
        print('No offering available to present the paywall.');
        return false;
      }

      await RevenueCatUI.presentPaywall(offering: targetOffering);
      return true;
    } catch (e) {
      print('Failed to present paywall: $e');
      return false;
    }
  }
}
