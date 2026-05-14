import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Small wrapper around `url_launcher` + `share_plus` so callers don't need to
/// know about platform launch modes or share semantics.
class ExternalLinks {
  ExternalLinks._();

  /// Opens the Play Store listing for this app. Tries the `market://` deep
  /// link first (so the Play Store app handles it) and falls back to the
  /// public https listing in an in-app Custom Tab.
  static Future<bool> openPlayStore() async {
    final Uri marketUri = Uri.parse(AppConstants.playStoreDeepLink);
    try {
      if (await canLaunchUrl(marketUri)) {
        final bool ok = await launchUrl(
          marketUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (ok) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Play Store deep link failed: $e');
    }
    return _openInAppBrowser(AppConstants.playStoreUrl);
  }

  /// Opens an https URL in an in-app browser (Chrome Custom Tabs on Android,
  /// SFSafariViewController on iOS) — compliant with Google Play policies for
  /// privacy / terms surfaces.
  static Future<bool> openInAppBrowser(String url) => _openInAppBrowser(url);

  static Future<bool> _openInAppBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final bool ok = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (ok) {
        return true;
      }
    } catch (e) {
      debugPrint('In-app browser failed for $url: $e');
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('External browser fallback failed for $url: $e');
      return false;
    }
  }

  /// Triggers the system share sheet pre-populated with the app's marketing
  /// blurb + Play Store link.
  static Future<void> shareApp() {
    return SharePlus.instance.share(
      ShareParams(
        text: AppConstants.shareMessage,
        subject: AppConstants.appName,
      ),
    );
  }

  static Future<void> shareWallpaper({
    required String url,
    required String title,
    required bool isVideo,
  }) async {
    final Directory tempDir = await getTemporaryDirectory();
    final Uri uri = Uri.parse(url);
    final String sourceName = uri.pathSegments.isEmpty
        ? ''
        : uri.pathSegments.last.split('?').first;
    final String extension = _fileExtension(sourceName, isVideo);
    final String safeTitle = title
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final String fileName =
        '${safeTitle.isEmpty ? 'stitch_wallpaper' : safeTitle}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final String filePath = '${tempDir.path}${Platform.pathSeparator}$fileName';

    await Dio().download(url, filePath);

    await SharePlus.instance.share(
      ShareParams(
        text: title,
        subject: title,
        files: <XFile>[XFile(filePath)],
      ),
    );
  }

  static String _fileExtension(String fileName, bool isVideo) {
    final int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < fileName.length - 1) {
      return fileName.substring(dotIndex);
    }
    return isVideo ? '.mp4' : '.jpg';
  }
}
