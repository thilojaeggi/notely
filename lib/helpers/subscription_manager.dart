import 'package:notely/config/app_config.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionManager {
  static const String _apiKey = AppConfig.appleAPIKey;
  static const String _entitlementId = AppConfig.entitlementId;
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize services: $e');
    }
  }

  Future<bool> isSubscribed() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
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
