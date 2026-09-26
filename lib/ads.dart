import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// One interstitial at the natural breaks: a lost game and a collected cloud.
/// How often it appears is capped per user on the AdMob ad unit (1 per 3 minutes).
class Ads {
  static final _unit = kReleaseMode
      ? (Platform.isIOS
            ? 'ca-app-pub-4045474417631564/9698910474'
            : 'ca-app-pub-4045474417631564/4434889787')
      : (Platform.isIOS
            ? 'ca-app-pub-3940256099942544/4411468910'
            : 'ca-app-pub-3940256099942544/1033173712');
  static bool _ready = false;
  static InterstitialAd? _ad;

  /// Called once from main(); tests never start ads, so [show] stays a no-op there.
  static void start() {
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) => _begin()),
      (_) => _begin(),
    );
  }

  static Future<void> _begin() async {
    if (!await ConsentInformation.instance.canRequestAds()) return;
    await MobileAds.instance.initialize();
    _ready = true;
    _load();
  }

  static void _load() => InterstitialAd.load(
    adUnitId: _unit,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) => _ad = ad,
      onAdFailedToLoad: (_) => _ad = null,
    ),
  );

  /// Shows the loaded ad and completes when it closes; completes at once without one.
  static Future<void> show() {
    final ad = _ad;
    if (!_ready) return Future.value();
    if (ad == null) {
      _load();
      return Future.value();
    }
    _ad = null;
    final closed = Completer<void>();
    void done(Ad ad) {
      ad.dispose();
      _load();
      if (!closed.isCompleted) closed.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: done,
      onAdFailedToShowFullScreenContent: (ad, _) => done(ad),
    );
    ad.show();
    return closed.future;
  }
}
