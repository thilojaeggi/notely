import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class InitializationHelper {
  Future<FormError?> initialize() async {
    final completer = Completer<FormError?>();

    var params = ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: ["E1029A70-CBAC-4A16-9CDC-B0C17B220B56"],
      ),
    );
    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        await _loadConsentForm();
      } else {
        // There is no message to display,
        // so initialize the components here.
        await _initialize();
      }

      completer.complete();
    }, (error) {
      completer.complete(error);
    });

    return completer.future;
  }

  Future<void> _initialize() async {
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
        await _initialize();
        completer.complete();
      }
    }, (FormError? error) {
      completer.complete(error);
    });

    return completer.future;
  }

  Future<bool> changePrivacyPreferences() async {
    final completer = Completer<bool>();

    var params = ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyNotEea,
        testIdentifiers: ["E1029A70-CBAC-4A16-9CDC-B0C17B220B56"],
      ),
    );

    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        ConsentForm.loadConsentForm((consentForm) {
          consentForm.show((formError) async {
            await _initialize();
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
