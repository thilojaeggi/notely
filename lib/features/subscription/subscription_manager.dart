import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:notely/core/analytics/analytics_constants.dart';
import 'package:notely/core/analytics/analytics_service.dart';
import 'package:notely/core/config/app_config.dart';
import 'package:notely/features/widget/widget_sync_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:universal_io/universal_io.dart' show Platform;

class SubscriptionManager {
  static const String _entitlementId = AppConfig.entitlementId;
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  bool _isInitialized = false;
  final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);

  ValueListenable<bool> get isPremiumListenable => isPremiumNotifier;
  bool get isPremium => isPremiumNotifier.value;

  String? get _apiKey {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isMacOS) {
      return AppConfig.appleAPIKey;
    } else if (Platform.isAndroid) {
      return AppConfig.googleAPIKey;
    }
    return null;
  }

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    final apiKey = _apiKey;
    if (apiKey == null) return;

    try {
      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      final subscribed = await isSubscribed();
      await _updatePremiumState(subscribed);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        final isActive =
            customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
        _updatePremiumState(isActive);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize subscription services: $e');
    }
  }

  Future<void> _updatePremiumState(bool isPremium) async {
    if (isPremiumNotifier.value != isPremium) {
      isPremiumNotifier.value = isPremium;
    }
    _setPremiumUserProperty(isPremium);
    await _syncPremiumToWidget(isPremium);
    if (isPremium) {
      WidgetSyncService().syncScheduleToWidget();
    }
  }

  void _setPremiumUserProperty(bool isPremium) {
    AnalyticsService().setPremium(isPremium);
  }

  Future<void> _syncPremiumToWidget(bool isPremium) async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      // Write as string to avoid Dart bool → NSNumber bridging issues
      await HomeWidget.saveWidgetData<String>(
        'is_premium',
        isPremium ? 'true' : 'false',
      );
      await HomeWidget.updateWidget(
        name: 'ScheduleWidget',
        iOSName: 'ScheduleWidget',
      );
    } catch (e) {
      // ignore – widget may not be installed
    }
  }

  Future<bool> isSubscribed() async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      final isActive =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      await _updatePremiumState(isActive);
      return isActive;
    } catch (e) {
      debugPrint('Failed to check subscription status: $e');
      return isPremiumNotifier.value;
    }
  }

  Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    try {
      await initialize();
      AnalyticsService().logRestorePurchasesStarted();
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final isActive =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      await _updatePremiumState(isActive);
      if (isActive) {
        AnalyticsService().logRestorePurchasesSuccess();
      } else {
        AnalyticsService().logRestorePurchasesFailed(error: 'No active entitlement found');
      }
      return isActive;
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      AnalyticsService().logRestorePurchasesFailed(error: e.toString());
      return false;
    }
  }

  bool _isPaywallPresenting = false;

  Future<bool> presentNotelyPremiumPaywall({String source = PaywallSource.settingsBanner}) async {
    if (kIsWeb) return false;
    if (_isPaywallPresenting) {
      debugPrint('Paywall presentation already in progress, skipping duplicate.');
      return false;
    }
    _isPaywallPresenting = true;
    try {
      await initialize();
      await isSubscribed();
      final Offerings offerings = await Purchases.getOfferings();

      Offering? targetOffering = offerings.all['Notely Premium'];
      targetOffering ??= offerings.current;
      if (targetOffering == null && offerings.all.values.isNotEmpty) {
        targetOffering = offerings.all.values.first;
      }

      if (targetOffering == null) {
        debugPrint('No offering available to present the paywall.');
        return false;
      }

      AnalyticsService().logPaywallViewed(source: source);

      final paywallResult =
          await RevenueCatUI.presentPaywall(offering: targetOffering);
      final isSub = await isSubscribed();

      if (paywallResult == PaywallResult.purchased) {
        AnalyticsService().logPaywallPurchased(
          offeringId: targetOffering.identifier,
          source: source,
        );
      } else if (paywallResult == PaywallResult.restored) {
        AnalyticsService().logPaywallRestored(source: source);
      } else if (paywallResult == PaywallResult.cancelled) {
        AnalyticsService().logPaywallCancelled(source: source);
      } else if (paywallResult == PaywallResult.error) {
        AnalyticsService().logPaywallError(source: source);
      }

      return paywallResult == PaywallResult.purchased ||
          paywallResult == PaywallResult.restored ||
          isSub;
    } catch (e) {
      debugPrint('Failed to present paywall: $e');
      AnalyticsService().logPaywallError(error: e.toString(), source: source);
      return false;
    } finally {
      _isPaywallPresenting = false;
    }
  }
}
