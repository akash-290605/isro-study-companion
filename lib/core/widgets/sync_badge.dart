import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sync_model.dart';
import '../services/providers.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final status = syncService.status;

    Color color = const Color(0xFF10B981);
    IconData icon = Icons.cloud_done_rounded;

    switch (status) {
      case SyncStatus.synced:
        color = const Color(0xFF10B981);
        icon = Icons.cloud_done_rounded;
        break;
      case SyncStatus.localOnly:
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_outline_rounded;
        break;
      case SyncStatus.syncing:
        color = const Color(0xFFF59E0B);
        icon = Icons.sync_rounded;
        break;
      case SyncStatus.offline:
        color = const Color(0xFF64748B);
        icon = Icons.cloud_off_rounded;
        break;
    }

    final isCompact = MediaQuery.of(context).size.width < 500;
    final tooltipMessage = status == SyncStatus.localOnly
        ? 'Offline-ready: All notes, formulas, and progress are saved on this device.'
        : 'Sync status: ${status.label}';

    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          if (status == SyncStatus.localOnly) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('All changes are securely saved locally on this device. Sign in to sync with Firebase Cloud.'),
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Syncing with Firebase Cloud (downloading and uploading)...'),
              duration: Duration(seconds: 2),
            ),
          );

          await syncService.syncPendingData(forceFullBackup: true);

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Cloud sync complete! Downloaded and backed up your latest formulas and progress.'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 3),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              if (!isCompact) ...[
                const SizedBox(width: 6),
                Text(
                  status.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
