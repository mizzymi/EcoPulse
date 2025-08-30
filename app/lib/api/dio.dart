import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_token_provider.dart';

const String kApiBaseUrl = 'https://ecopulse.reimii.com';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (opts, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null) {
          opts.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(opts);
      },
    ),
  );
  return dio;
});
