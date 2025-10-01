import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';

class HouseholdCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onOpen;

  const HouseholdCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary.withOpacity(.9)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              top: -20,
              right: -10,
              child: _bubble(110, Colors.white.withOpacity(.18))),
          Positioned(
              bottom: -30,
              left: -20,
              child: _bubble(140, Colors.white.withOpacity(.12))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(amount,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onPressed: onOpen,
                      child: Text(S.of(context).openHousehold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
