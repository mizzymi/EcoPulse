import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import '../../../ui/theme/app_theme.dart';

class AddHouseCta extends StatelessWidget {
  final VoidCallback onTap;
  const AddHouseCta({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final accent = cs.primary;
    final surface = cs.surface;
    final border = cs.outlineVariant;

    return Align(
      alignment: Alignment.center, // or Alignment.centerLeft
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 425), // 👈 adjust if you want
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18), // less heavy than .30
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // 👈 shrink-wrap horizontally
                  children: [
                    Flexible(
                      child: Text(
                        S.of(context).createOrJoinTitle,
                        maxLines: 1, // 👈 makes it more compact
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        S.of(context).openCta,
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
