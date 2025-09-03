// Tarjeta de resumen mensual.
// Muestra el "closing" grande con color (verde/rojo) y debajo el neto.
// Al tocar, puede ejecutar un callback (ej. abrir ese mes).

import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String month;
  final double opening, income, expense, net, closing;
  final VoidCallback? onTap; // Callback opcional al tocar la tarjeta

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

  @override
  Widget build(BuildContext context) {
    final netPos = net >= 0;
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
                    'Resumen $month',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Saldo final (closing) grande y coloreado
                      Text(
                        closing.toStringAsFixed(2),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: closing >= 0 ? Colors.teal : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      // Neto del mes en tono más sutil
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Datos breves: gastos/ingresos
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Neto del mes: ${(netPos ? '+' : '') + net.toStringAsFixed(2)}',
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
                      'Inicio de mes: ${opening.toStringAsFixed(2)}',
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
              Row(
                children: [
                  Expanded(
                    child: Text('Gastos: ${expense.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: Text('Ingresos: ${income.toStringAsFixed(2)}'),
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
