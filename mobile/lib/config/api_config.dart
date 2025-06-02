import 'platform_config.dart';

class ApiConfig {
  // URLs dynamiques selon la plateforme
  static String get userServiceBaseUrl => PlatformConfig.userServiceBaseUrl;
  static String get contentServiceBaseUrl => PlatformConfig.contentServiceBaseUrl;
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // Debug info
  static void printConfig() {
    print('=== API Configuration ===');
    print('Platform: ${PlatformConfig.currentPlatform}');
    print('User Service: $userServiceBaseUrl');
    print('Content Service: $contentServiceBaseUrl');
    print('========================');
  }
}
