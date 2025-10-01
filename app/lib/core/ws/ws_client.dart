import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../providers/auth_token_provider.dart';
import '../config/app_config.dart';

final wsProvider = Provider<IO.Socket?>((ref) {
  final token = ref.watch(authTokenProvider);
  if (token == null) return null;

  final socket = IO.io(
    AppConfig.wsBaseUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setPath('/realtime')
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .enableForceNew()
        .build(),
  );

  // Basic lifecycle
  socket.onConnect((_) {
    // Connected
  });
  socket.onReconnectAttempt((_) {});
  socket.onDisconnect((_) {});

  ref.onDispose(() {
    if (socket.connected) {
      socket.dispose();
    } else {
      socket.close();
    }
  });
  return socket;
});

/// Simple broadcast stream to surface text notifications to UI.
final wsNotificationsProvider = Provider<Stream<String>>((ref) {
  final controller = StreamController<String>.broadcast();
  final s = ref.read(wsProvider);
  if (s == null) {
    // If not authenticated, emit nothing
    return controller.stream;
  }

  void notify(dynamic data) {
    if (data is String) {
      controller.add(data);
    } else if (data is Map && data['message'] is String) {
      controller.add(data['message'] as String);
    }
  }

  // Example server events
  s.on('join_request_new', (data) {
    final email = (data is Map && data['requesterEmail'] is String)
        ? data['requesterEmail'] as String
        : 'Alguien';
    controller.add('Nueva solicitud de unión: $email');
  });

  s.on('join_request_decision', (data) {
    final status = (data is Map) ? data['status'] : null;
    if (status == 'APPROVED') {
      controller.add('¡Tu solicitud fue aprobada!');
    } else if (status == 'REJECTED') {
      controller.add('Tu solicitud fue rechazada.');
    }
  });

  ref.onDispose(() => controller.close());
  return controller.stream;
});

