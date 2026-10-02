import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static String version = '1.1.0';
  static String buildNumber = '3';
  static String appName = 'API Lab';

  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        version = info.version;
      }
      if (info.buildNumber.isNotEmpty) {
        buildNumber = info.buildNumber;
      }
      if (info.appName.isNotEmpty) {
        appName = info.appName;
      }
    } catch (_) {
      // Fallback for headless tests without platform channels
    }
  }

  static String get formattedVersion => 'v$version';
  static String get fullVersionString =>
      '$appName v$version • Desktop HTTP/HTTPS Interceptor, Mock Engine & MCP AI Agent Hub';
}
