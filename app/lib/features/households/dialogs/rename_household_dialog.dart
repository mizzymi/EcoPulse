// Diálogo reutilizable para renombrar la casa.
// Retorna el nuevo nombre (String) si se guardó, o null si se canceló.
//
// Requiere que el backend implemente PATCH /households/:id con body { name: string }.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<String?> showRenameHouseholdDialog(
  BuildContext context,
  Dio dio, {
  required String initialName,
  required String householdId,
}) async {
  final ctrl = TextEditingController(text: initialName);
  bool saving = false;

  final result = await showDialog<String?>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: const Text('Cambiar nombre de la casa'),
        content: TextField(
          controller: ctrl,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Piso Centro',
            border: OutlineInputBorder(),
          ),
          maxLength: 64, // Debe coincidir con validación backend (si la tienes)
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () async {
                    final newName = ctrl.text.trim();
                    if (newName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('El nombre no puede estar vacío')),
                      );
                      return;
                    }
                    setStateDialog(() => saving = true);
                    try {
                      // PATCH al backend
                      await dio.patch('/households/$householdId',
                          data: {'name': newName});
                      if (context.mounted) {
                        Navigator.pop(ctx, newName); // devuelve newName
                      }
                    } on DioException catch (e) {
                      // Muestra error del backend si viene con 'message'
                      final msg = e.response?.data is Map &&
                              (e.response!.data as Map)['message'] != null
                          ? (e.response!.data as Map)['message'].toString()
                          : (e.message ?? 'No se pudo actualizar el nombre');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } finally {
                      if (context.mounted) {
                        setStateDialog(() => saving = false);
                      }
                    }
                  },
            icon: saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  return result; // String con el nuevo nombre o null si canceló
}
