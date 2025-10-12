import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppReloader extends StatefulWidget {
  const AppReloader({
    super.key,
    required this.bootstrapContainer,
    required this.child,
  });

  /// Crea un ProviderContainer nuevo (puede ser async: prefs, tokens, etc.)
  final Future<ProviderContainer> Function() bootstrapContainer;
  final Widget child;

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AppReloaderState>()?.restart();
  }

  @override
  State<AppReloader> createState() => _AppReloaderState();
}

class _AppReloaderState extends State<AppReloader> {
  ProviderContainer? _container;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  Future<void> _rebuild() async {
    setState(() => _loading = true);
    final newContainer = await widget.bootstrapContainer();
    final old = _container;
    if (!mounted) {
      newContainer.dispose();
      return;
    }
    setState(() {
      _container = newContainer;
      _loading = false;
    });
    old?.dispose(); // evita pérdidas de memoria
  }

  void restart() => _rebuild();

  @override
  Widget build(BuildContext context) {
    if (_loading || _container == null) {
      // Spinner mínimo antes de tener MaterialApp
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return UncontrolledProviderScope(
      container: _container!,
      child: widget.child,
    );
  }
}
