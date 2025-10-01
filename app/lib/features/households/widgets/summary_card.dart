// Tarjeta de resumen mensual.
// Muestra el "closing" grande con color (verde/rojo) y debajo el neto.
// Al tocar, puede ejecutar un callback (ej. abrir ese mes).

import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final String month;
  final double opening, income, expense, net, closing;
  final VoidCallback? onTap; 

  const SummaryCard({
    super.key,
    required this.month,
    required this.opening,
    required this.income,
    required this.expense,
    required this.net,
    required this.closing,
    this.onTap,
  });

  String _fmtNum(BuildContext context, double value, {bool withSign = false}) {
    final locale = Localizations.localeOf(context).toString();
    final f = NumberFormat.decimalPattern(locale);
    // fuerza 2 decimales
    f.minimumFractionDigits = 2;
    f.maximumFractionDigits = 2;
    final abs = f.format(value.abs());
    if (!withSign) return f.format(value);
    final sign = value > 0 ? '+' : (value < 0 ? '-' : '');
    return '$sign$abs';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Card(
      child: InkWell(
        onTap: onTap, // Dispara navegación si se provee
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Encabezado: "Resumen YYYY-MM" + Saldo final grande + Neto debajo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.summaryTitle(month),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Saldo final (closing) grande y coloreado
                      Text(
                        _fmtNum(context, closing),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: closing >= 0 ? Colors.teal : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Datos breves: neto / inicio de mes
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.netOfMonth(_fmtNum(context, net, withSign: true)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.openingOfMonth(_fmtNum(context, opening)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ),
                ],
              ),

              // Gastos / Ingresos
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.expensesLabel(_fmtNum(context, expense)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.incomeLabel(_fmtNum(context, income)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
