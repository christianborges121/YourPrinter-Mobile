import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../state/connection_provider.dart';
import '../../state/printer_context_provider.dart';
import '../../state/telemetry_provider.dart';
import '../common/not_configured_view.dart';
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
    final connState = ref.watch(connectionProvider);

    if (connState.status == ServerConnectionStatus.unreachable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Dashboard'), centerTitle: true),
        body: const NotConfiguredView(),
      );
    }

    if (contextState.isLoading && contextState.contexts.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
      );
    }

    if (contextState.contexts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Dashboard'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.printer, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No Printers Connected', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'YourPrinter server is running, but no printers are active. Add your printer in the desktop application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.read(printerContextProvider.notifier).fetchContexts(),
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Refresh Printers'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: contextState.contexts.any((c) => c.contextId == contextState.activeContextId)
                ? contextState.activeContextId
                : contextState.contexts.first.contextId,
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
