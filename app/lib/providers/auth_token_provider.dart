import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAuthTokenKey = 'auth_token';

final authTokenProvider = StateProvider<String?>((ref) => null);

final loadAuthTokenProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(kAuthTokenKey);
  ref.read(authTokenProvider.notifier).state = token;
});

final authTokenControllerProvider = Provider<AuthTokenController>((ref) {
  return AuthTokenController(ref);
});

class AuthTokenController {
  AuthTokenController(this._ref);
  final Ref _ref;

  Future<void> set(String token) async {
    _ref.read(authTokenProvider.notifier).state = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAuthTokenKey, token);
  }

  Future<void> clear() async {
    _ref.read(authTokenProvider.notifier).state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kAuthTokenKey);
  }
}
