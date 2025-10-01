/// glass_shell.dart
/// --------------------------------------------
/// Contenedor visual con esquinas redondeadas y ligera transparencia.
/// Sustituye al uso directo de `GlassCard` en el topbar para que sea
/// reutilizable sin dependencias cruzadas.

import 'package:flutter/material.dart';

class GlassShell extends StatelessWidget {
  const GlassShell({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface.withOpacity(.6),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.outline.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withOpacity(.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
