import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_token_provider.dart';

const String kWsBase = 'https://ecopulse.reimii.com';

final wsProvider = Provider<IO.Socket?>((ref) {
  final token = ref.watch(authTokenProvider);
  if (token == null) return null;

  final socket = IO.io(
    kWsBase,
    IO.OptionBuilder()
        .setTransports(['websocket'])  
        .setPath('/realtime')           
        .setExtraHeaders({
          'Authorization': 'Bearer $token',
        })
        .disableAutoConnect()
        .build(),
  );

  socket.onConnect((_) => print('[WS] conectado'));
  socket.onConnectError((e) => print('[WS] connect_error: $e'));
  socket.onError((e) => print('[WS] error: $e'));
  socket.onDisconnect((_) => print('[WS] desconectado'));

  socket.connect();

  ref.onDispose(() {
    socket.dispose();
  });

  return socket;
});

void listenJoinEvents(WidgetRef ref, void Function(String msg) show) {
  final s = ref.read(wsProvider);
  if (s == null) return;

  s.on('join_request_new', (data) {
    final email = data?['requesterEmail'] ?? 'Alguien';
    show('Nueva solicitud de unión: $email');
  });

  s.on('join_request_decision', (data) {
    final status = data?['status'];
    if (status == 'APPROVED') {
      show('¡Tu solicitud fue aprobada!');
    } else if (status == 'REJECTED') {
      show('Tu solicitud fue rechazada.');
    }
  });
}
