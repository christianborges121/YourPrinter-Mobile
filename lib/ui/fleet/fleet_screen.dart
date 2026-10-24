import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../state/fleet_provider.dart';
import '../../state/printer_context_provider.dart';
import 'fleet_printer_card.dart';

class FleetScreen extends ConsumerWidget {
  final Function(int) onTabSelected;

  const FleetScreen({super.key, required this.onTabSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetState = ref.watch(fleetProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Fleet Overview'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${fleetState.printers.length} Printers',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Refresh Fleet',
            onPressed: () => ref.read(fleetProvider.notifier).fetchOverview(),
          ),
        ],
      ),
      body: fleetState.isLoading && fleetState.printers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : fleetState.printers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.printer, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('No printers detected', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Add printers in YourPrinter server settings', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.accentGreen,
                  onRefresh: () => ref.read(fleetProvider.notifier).fetchOverview(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: fleetState.printers.length,
                    itemBuilder: (context, index) {
                      final printer = fleetState.printers[index];
                      return FleetPrinterCard(
                        printer: printer,
                        onTap: () {
                          if (printer.contextId != null) {
                            ref.read(printerContextProvider.notifier).switchContext(printer.contextId!);
                          }
                          // Switch to Dashboard Tab (index 1)
                          onTabSelected(1);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
