import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppReloader extends StatefulWidget {
  final Widget child;
  const AppReloader({super.key, required this.child});

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AppReloaderState>()?.restart();
  }

  @override
  State<AppReloader> createState() => _AppReloaderState();
}

class _AppReloaderState extends State<AppReloader> {
  Key _key = UniqueKey();
  void restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    // Nuevo ProviderContainer al cambiar la key
    return KeyedSubtree(
      key: _key,
      child: const ProviderScope(
        child: _AppChild(),
      ),
    );
  }
}

class _AppChild extends StatelessWidget {
  const _AppChild();

  @override
  Widget build(BuildContext context) => widget.child;
}