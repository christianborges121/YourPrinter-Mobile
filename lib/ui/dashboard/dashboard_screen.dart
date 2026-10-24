import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../state/printer_context_provider.dart';
import '../../state/telemetry_provider.dart';
import '../controls/control_panel_card.dart';
import '../controls/watchdog_sheet.dart';
import 'ams_spool_card.dart';
import 'camera_panel.dart';
import 'job_progress_card.dart';
import 'temperature_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextState = ref.watch(printerContextProvider);
    final telemetry = ref.watch(telemetryProvider);

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: contextState.activeContextId,
            dropdownColor: AppColors.surface,
            icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textPrimary),
            items: contextState.contexts.map((ctx) {
              return DropdownMenuItem<String>(
                value: ctx.contextId,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ctx.isConnected ? AppColors.accentGreen : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ctx.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${ctx.model})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newId) {
              if (newId != null) {
                ref.read(printerContextProvider.notifier).switchContext(newId);
              }
            },
          ),
        ),
        actions: [
          // Watchdog AI Pill
          if (telemetry.status?.watchdog != null)
            IconButton(
              icon: Icon(
                LucideIcons.shieldCheck,
                size: 20,
                color: telemetry.status!.watchdog!.online ? AppColors.accentGreen : AppColors.textMuted,
              ),
              tooltip: 'AI Watchdog Guard',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  builder: (_) => const WatchdogSheet(),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentGreen,
        onRefresh: () async {
          await ref.read(printerContextProvider.notifier).fetchContexts();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: const [
            CameraPanel(),
            SizedBox(height: 10),
            JobProgressCard(),
            SizedBox(height: 10),
            TemperatureCard(),
            SizedBox(height: 10),
            AmsSpoolCard(),
            SizedBox(height: 10),
            ControlPanelCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
