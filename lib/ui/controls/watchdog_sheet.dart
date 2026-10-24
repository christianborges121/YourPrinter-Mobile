import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../state/telemetry_provider.dart';

class WatchdogSheet extends ConsumerStatefulWidget {
  const WatchdogSheet({super.key});

  @override
  ConsumerState<WatchdogSheet> createState() => _WatchdogSheetState();
}

class _WatchdogSheetState extends ConsumerState<WatchdogSheet> {
  double _threshold = 0.20;
  bool _autoPause = true;

  @override
  void initState() {
    super.initState();
    final watchdog = ref.read(telemetryProvider).status?.watchdog;
    if (watchdog != null) {
      _threshold = watchdog.threshold;
      _autoPause = watchdog.autoPauseEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final watchdog = telemetry.status?.watchdog;
    final printerService = ref.read(printerServiceProvider);
    final apiClient = ref.read(apiClientProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: AppColors.accentGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Watchdog Guard (Darknet YOLO)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const Divider(height: 16),

          // Status & Confidence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ${watchdog?.state.toUpperCase() ?? 'OFFLINE'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (watchdog?.online ?? false) ? AppColors.accentGreen : AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              Text(
                'Defect Risk: ${((watchdog?.confidence ?? 0.0) * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (watchdog?.confidence ?? 0.0) >= _threshold ? AppColors.error : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sensitivity Threshold Slider
          Text('Detection Sensitivity: ${(_threshold * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13)),
          Slider(
            value: _threshold,
            min: 0.05,
            max: 0.95,
            divisions: 18,
            activeColor: AppColors.accentGreen,
            onChanged: (val) {
              setState(() => _threshold = val);
            },
            onChangeEnd: (val) {
              printerService.updateWatchdogConfig(threshold: val, autoPause: _autoPause);
            },
          ),
          const SizedBox(height: 8),

          // Auto-Pause Switch
          SwitchListTile(
            title: const Text('Auto-Pause on Defect', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Automatically pause printer when failure threshold is exceeded', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: _autoPause,
            activeThumbColor: AppColors.accentGreen,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _autoPause = val);
              printerService.updateWatchdogConfig(threshold: _threshold, autoPause: val);
            },
          ),
          const SizedBox(height: 12),

          // Latest Annotated AI Snapshot
          const Text('Latest Inspection Snapshot:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                '${apiClient.baseUrl}${ApiEndpoints.watchdogSnapshotLatest}',
                headers: apiClient.authToken != null ? {'Authorization': 'Bearer ${apiClient.authToken}'} : null,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black45,
                  child: const Center(child: Text('No AI snapshot available yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
