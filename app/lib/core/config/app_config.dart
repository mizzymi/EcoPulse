import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static final String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static final String wsBaseUrl  = dotenv.env['WS_BASE_URL'] ?? '';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
