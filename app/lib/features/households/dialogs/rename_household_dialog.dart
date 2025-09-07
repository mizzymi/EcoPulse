// Diálogo reutilizable para renombrar la cuenta.
// Retorna el nuevo nombre (String) si se guardó, o null si se canceló.
//
// Requiere que el backend implemente PATCH /households/:id con body { name: string }.

import 'package:dio/dio.dart';
import 'package:ecopulse/l10n/l10n.dart';
import 'package:flutter/material.dart';

Future<String?> showRenameHouseholdDialog(
  BuildContext context,
  Dio dio, {
  required String initialName,
  required String householdId,
}) async {
  final s = S.of(context);
  final ctrl = TextEditingController(text: initialName);
  bool saving = false;

  final result = await showDialog<String?>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: Text(s.renameHouseholdTitle),
        content: TextField(
          controller: ctrl,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: s.nameLabel,
            hintText: s.nameHint,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          maxLength: 64, // Alinear con validación backend si aplica
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx, null),
            child: Text(s.cancel),
          ),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () async {
                    final newName = ctrl.text.trim();
                    if (newName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.nameEmptyToast)),
                      );
                      return;
                    }
                    setStateDialog(() => saving = true);
                    try {
                      await dio.patch(
                        '/households/$householdId',
                        data: {'name': newName},
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx, newName); // devuelve newName
                      }
                    } on DioException catch (e) {
                      final msg = e.response?.data is Map &&
                              (e.response!.data as Map)['message'] != null
                          ? (e.response!.data as Map)['message'].toString()
                          : (e.message ?? s.updateNameFailed);
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(s.save),
          ),
        ],
      ),
    ),
  );

  return result; // String con el nuevo nombre o null si canceló
}
