import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class DeleteFolderDialog extends StatefulWidget {
  const DeleteFolderDialog({super.key});

  @override
  State<DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<DeleteFolderDialog> {
  bool _purge = false; // Default to keep contents (pop up)

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.deleteFolderTitle,
        style: const TextStyle(
          color: Color(0xFF17324B),
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      content: RadioGroup<bool>(
        groupValue: _purge,
        onChanged: (val) => setState(() => _purge = val!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              value: false,
              activeColor: const Color(0xFF2E4E69),
              title: Text(
                l10n.deleteFolderOptionPopTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF20364B),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  l10n.deleteFolderOptionPopMessage,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF587185)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<bool>(
              value: true,
              activeColor: Colors.red[400],
              title: Text(
                l10n.deleteFolderOptionAllTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.red[400],
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  l10n.deleteFolderOptionAllMessage,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF587185)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // cancel
          child: Text(
            l10n.cancelButtonLabel,
            style: const TextStyle(color: Color(0xFF4E677D)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_purge), // return selection
          style: ElevatedButton.styleFrom(
            backgroundColor: _purge ? Colors.red[400] : const Color(0xFF2E4E69),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(l10n.deleteButtonLabel),
        ),
      ],
    );
  }
}
