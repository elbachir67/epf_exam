import 'package:flutter/foundation.dart';

class PlatformConfig {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop =>
      isWindows ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux));

  // URLs adaptées selon la plateforme
  static String get userServiceBaseUrl {
    if (isWeb || isDesktop) {
      // Pour Web et Desktop, utiliser localhost directement
      return 'http://localhost:8080/api';
    } else if (isAndroid) {
      // Pour Android emulator
      return 'http://10.0.2.2:8080/api';
    } else {
      // Pour iOS simulator
      return 'http://localhost:8080/api';
    }
  }

  static String get contentServiceBaseUrl {
    if (isWeb || isDesktop) {
      return 'http://localhost:3000/api';
    } else if (isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  // Obtenir le nom de la plateforme actuelle
  static String get currentPlatform {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macOS';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'Linux';
    return 'Unknown';
  }
}
