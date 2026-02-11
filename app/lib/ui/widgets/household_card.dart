import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HouseholdCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final VoidCallback onOpen;
  final bool danger;

  const HouseholdCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onOpen,
    this.danger = false,
  });

  Widget _localizedRichAmount(BuildContext context, double value,
      {required Color color}) {
    final locale =
        Intl.canonicalizedLocale(Localizations.localeOf(context).toString());
    final nf = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;

    final s = nf.format(value.abs());
    final decimalSep = nf.symbols.DECIMAL_SEP;
    final minus = nf.symbols.MINUS_SIGN;

    final i = s.lastIndexOf(decimalSep);
    final intPart = i == -1 ? s : s.substring(0, i);
    final decPart = i == -1 ? '00' : s.substring(i + 1);

    final big = TextStyle(
      color: color,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.05,
    );
    final small = TextStyle(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      height: 1,
    );

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: big,
        children: [
          if (value < 0) TextSpan(text: minus),
          TextSpan(text: intPart),
          TextSpan(text: decimalSep),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Text(decPart, style: small),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 45/45/10: keep most elements neutral; use teal only in accents.
    final accent = danger ? cs.error : cs.primary;
    final surface =
        danger ? cs.error.withOpacity(.65) : cs.primary.withOpacity(.65);
    ;
    final border = cs.outlineVariant;
    final textMain = cs.onSurface;
    final textSub = cs.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle bubbles but in neutral (avoid extra color)
            Positioned(
              top: -26,
              right: -14,
              child: _bubble(120, accent.withOpacity(.35)),
            ),
            Positioned(
              bottom: -34,
              left: 10, // avoid the accent bar
              child: _bubble(150, accent.withOpacity(.35)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _localizedRichAmount(
                          context,
                          amount,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Use your theme FilledButton styling; override only if needed.
                      FilledButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(S.of(context).openHousehold),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
}
