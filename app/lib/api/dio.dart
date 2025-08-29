import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_token_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final token = ref.watch(authTokenProvider);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (opt, handler) {
      if (token != null && token.isNotEmpty) {
        opt.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(opt);
    },
  ));
  return dio;
});
