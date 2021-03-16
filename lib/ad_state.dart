
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdState {
  Future<InitializationStatus> initialization;

  AdState(this.initialization);
  AdListener get adListener => _adListener;

  AdListener _adListener = AdListener(
    onAdLoaded: (ad) => print('Ad Loaded : ${ad.adUnitId}.'),
    onAdClosed: (ad) => print('Ad Closed : ${ad.adUnitId}.'),
    onAdFailedToLoad: (ad, error) => print('Ad failed to load: ${ad.adUnitId}, $error'),
    onAdOpened: (ad) => print('Ad Opened : ${ad.adUnitId}.'),
    onAppEvent: (ad, name, data) => print('App event ${ad.adUnitId}, $name, $data '),
    onApplicationExit: (ad) => print('App exit : ${ad.adUnitId}.'),
    onNativeAdClicked: (nativeAd) => print('Native ad clicked: ${nativeAd.adUnitId}.'),
    onNativeAdImpression: (nativeAd) => print('Native ad impression: ${nativeAd.adUnitId}.'),
    onRewardedAdUserEarnedReward: (ad, reward) => print('User name reward : ${ad.adUnitId}, ${reward.amount} ${reward.type}.')
  );
}