import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../models/material_station.dart';
import '../../state/telemetry_provider.dart';

class AmsSpoolCard extends ConsumerWidget {
  const AmsSpoolCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final station = telemetry.materialStation;
    final activeSpool = telemetry.activeSpool;

    if ((station == null || !station.connected) && activeSpool == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.circleDot, size: 16, color: AppColors.accentGreen),
                SizedBox(width: 8),
                Text(
                  'Material & Spool Station',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Material Station Slots
            if (station != null && station.slots.isNotEmpty) ...[
              Row(
                children: [
                  for (final slot in station.slots)
                    Expanded(
                      child: _buildSlotItem(slot),
                    ),
                ],
              ),
              if (activeSpool != null) const Divider(height: 20),
            ],

            // Active Spoolman Details
            if (activeSpool != null) ...[
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _parseColor(activeSpool.colorHex),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activeSpool.vendor ?? 'Generic'} ${activeSpool.name}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${activeSpool.material ?? 'PLA'} Â· ${activeSpool.remainingWeight.toStringAsFixed(0)}g left',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotItem(MaterialSlot slot) {
    final color = _parseColor(slot.colorHex);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: slot.isActive ? AppColors.accentGreenSubtle : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: slot.isActive ? AppColors.accentGreen : AppColors.border,
          width: slot.isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            slot.type ?? 'Slot ${slot.id}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (slot.remainingPercent != null) ...[
            const SizedBox(height: 2),
            Text(
              '${slot.remainingPercent!.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.accentGreen;
    try {
      final clean = hexString.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.accentGreen;
    }
  }
}
