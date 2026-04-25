import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._(); // private constructor to prevent instantiation

  // RevenueCat
  static const String appleAPIKey = 'appl_OdJAftPJwqYMQPIkPlewnkIWfRq';
  static const String testAPIKey = 'test_hszPmfjKYpnwtuEtEsgjXPyszkv';
  static const String googleAPIKey = 'goog_ONzxOTLPFpvFZRPrJdnXihajDVp';
  static const String entitlementId = 'Notely Premium';

  static const String authProxyUrl = 'https://auth.notely.ch';
  static const bool forceWebFlow = true;
}
