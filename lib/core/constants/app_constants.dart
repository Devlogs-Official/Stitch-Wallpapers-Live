class AppConstants {
  AppConstants._();

  /// Display name shown to the user.
  static const String appName = '';

  /// Marketing version shown in the settings screen footer.
  static const String appVersion = '1.0.0';

  /// Android applicationId / Play Store package id used by Rate + Share.
  static const String androidPackageId = 'com.example.stitch_live_wallpapers';

  /// MethodChannel for Android live wallpaper (must match MainActivity).
  static const String androidLiveWallpaperMethodChannel =
      'wallpaper.apply/channel';

  /// Public Play Store listing URL.
  static String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// `market://` deep link preferred when the Play Store app is installed.
  static String get playStoreDeepLink =>
      'market://details?id=$androidPackageId';

  /// Privacy Policy hosted page (must be reachable from Play Console listing).
  static const String privacyPolicyUrl =
      'https://www.devlogs.pro/privacy-policy/stitch-wallpapers';

  /// Terms & Conditions hosted page.
  static const String termsAndConditionsUrl =
      'https://www.devlogs.pro/terms-and-conditions/stitch-wallpapers';

  /// Pre-populated text used by the Share Sheet.
  static String get shareMessage =>
      'Check out $appName - Beautiful Stitch live and static wallpapers.\n$playStoreUrl';
}
