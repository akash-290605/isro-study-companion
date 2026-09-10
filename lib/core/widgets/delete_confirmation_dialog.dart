import 'package:flutter/material.dart';

enum DeleteMode {
  permanent,
  localOnly,
}

class DeleteConfirmationResult {
  final DeleteMode mode;
  final bool deleteAssociatedItems;

  const DeleteConfirmationResult({
    required this.mode,
    this.deleteAssociatedItems = false,
  });

  bool get isPermanent => mode == DeleteMode.permanent;
  bool get isLocalOnly => mode == DeleteMode.localOnly;
  bool get deleteAssociatedQuestions => deleteAssociatedItems;
}

class DeleteConfirmationDialog extends StatefulWidget {
  final String title;
  final String itemName;
  final String itemType;
  final String? associatedItemsNotice;
  final bool hasAssociatedItems;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.itemName,
    required this.itemType,
    this.associatedItemsNotice,
    this.hasAssociatedItems = false,
  });

  static Future<DeleteConfirmationResult?> show({
    required BuildContext context,
    String? title,
    required String itemName,
    required String itemType,
    String? associatedItemsNotice,
    bool hasAssociatedItems = false,
    bool hasAssociatedQuestions = false,
    int associatedQuestionsCount = 0,
  }) {
    final effectiveHasAssociated = hasAssociatedItems || hasAssociatedQuestions || (associatedQuestionsCount > 0);
    final effectiveTitle = title ?? 'Delete $itemType?';
    final effectiveNotice = associatedItemsNotice ??
        (effectiveHasAssociated
            ? 'Also delete all $associatedQuestionsCount questions extracted from this $itemType'
            : null);

    return showDialog<DeleteConfirmationResult>(
      context: context,
      builder: (ctx) => DeleteConfirmationDialog(
        title: effectiveTitle,
        itemName: itemName,
        itemType: itemType,
        associatedItemsNotice: effectiveNotice,
        hasAssociatedItems: effectiveHasAssociated,
      ),
    );
  }

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool _deleteAssociated = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this ${widget.itemType.toLowerCase()}?',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              ),
              child: Text(
                widget.itemName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            if (widget.hasAssociatedItems && widget.associatedItemsNotice != null) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: CheckboxListTile(
                  dense: true,
                  value: _deleteAssociated,
                  activeColor: Colors.red,
                  title: Text(
                    widget.associatedItemsNotice!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (val) {
                    setState(() => _deleteAssociated = val ?? false);
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Choose deletion option:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Permanently: Deletes from this device AND the Firebase database (never returns on refresh).',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.devices_rounded, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Local Only: Removes from this device only, keeping cloud backup intact.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.visibility_off_outlined, size: 16),
          label: const Text('Remove Locally'),
          onPressed: () {
            Navigator.of(context).pop(
              DeleteConfirmationResult(
                mode: DeleteMode.localOnly,
                deleteAssociatedItems: _deleteAssociated,
              ),
            );
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete_forever_rounded, size: 16),
          label: const Text('Delete Permanently'),
          onPressed: () {
            Navigator.of(context).pop(
              DeleteConfirmationResult(
                mode: DeleteMode.permanent,
                deleteAssociatedItems: _deleteAssociated,
              ),
            );
          },
        ),
      ],
    );
  }
}
