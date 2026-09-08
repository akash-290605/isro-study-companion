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
        color = const Color(0xFF10B981); // Emerald
        icon = Icons.cloud_done_rounded;
        break;
      case SyncStatus.syncing:
        color = const Color(0xFFF59E0B); // Amber
        icon = Icons.sync_rounded;
        break;
      case SyncStatus.offline:
        color = const Color(0xFF94A3B8); // Slate
        icon = Icons.cloud_off_rounded;
        break;
    }

    final isCompact = MediaQuery.of(context).size.width < 500;

    return Tooltip(
      message: 'Sync status: ${status.label}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          syncService.syncPendingData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync status: ${status.label}. Checking cloud updates...'),
              duration: const Duration(seconds: 2),
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

