import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class InitializationHelper {
  Future<void> initialize() async {
    await MobileAds.instance.initialize();

    /**
     * Here you can place any other initialization of any
     * other component that depends on consent management,
     * for example the initialization of Google Analytics
     * or Google Crashlytics would go here.
     */
  }

  Future<FormError?> _loadConsentForm() async {
    final completer = Completer<FormError?>();

    ConsentForm.loadConsentForm((consentForm) async {
      final status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.required) {
        consentForm.show((formError) {
          completer.complete(_loadConsentForm());
        });
      } else {
        // The user has chosen an option,
        // it's time to initialize the ads component.
        await initialize();
        completer.complete();
      }
    }, (FormError? error) {
      completer.complete(error);
    });

    return completer.future;
  }

  Future<bool> changePrivacyPreferences() async {
    final completer = Completer<bool>();

    final params = ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        // Or DebugGeography.debugGeographyNotEea to simulate outside of the EEA
      ),
    );

    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        ConsentForm.loadConsentForm((consentForm) {
          consentForm.show((formError) async {
            await initialize();
            completer.complete(true);
          });
        }, (formError) {
          completer.complete(false);
        });
      } else {
        completer.complete(false);
      }
    }, (error) {
      completer.complete(false);
    });

    return completer.future;
  }
}
