class AppConfig {
  AppConfig._();

  static final String apiBaseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://ecopulse.reimii.com');

  static final String wsBaseUrl =
      const String.fromEnvironment('WS_BASE_URL', defaultValue: 'https://ecopulse.reimii.com');

  /// Generic timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
