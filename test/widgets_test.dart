import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashforge_mobile/services/preferences_service.dart';
import 'package:flashforge_mobile/state/auth_provider.dart';
import 'package:flashforge_mobile/ui/common/status_badge.dart';
import 'package:flashforge_mobile/ui/common/skeleton_shimmer.dart';
import 'package:flashforge_mobile/ui/dashboard/job_progress_card.dart';
import 'package:flashforge_mobile/state/telemetry_provider.dart';
import 'package:flashforge_mobile/models/printer_status.dart';

class TestTelemetryNotifier extends StateNotifier<TelemetryState> implements TelemetryNotifier {
  TestTelemetryNotifier([super.state = const TelemetryState(isLoading: true)]);

  @override
  void resetForContextSwitch() {
    state = const TelemetryState(isLoading: true);
  }

  @override
  Future<void> fetchStatus({String? contextId}) async {}

  @override
  void updateStatus(PrinterStatusData newStatus) {
    state = state.copyWith(isLoading: false, status: newStatus);
  }
}

void main() {
  late PreferencesService testPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await PreferencesService.create();
  });

  group('UI Widgets Tests', () {
    testWidgets('StatusBadge displays correct text for printing state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Printing',
              isPrinting: true,
              isCompleted: false,
            ),
          ),
        ),
      );

      expect(find.text('Printing'), findsOneWidget);
    });

    testWidgets('StatusBadge displays correct text for completed state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Completed',
              isPrinting: false,
              isCompleted: true,
            ),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('SkeletonShimmer renders with specified dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(
              width: 120,
              height: 24,
              borderRadius: 6,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('JobProgressCard renders shimmer skeleton when telemetry is loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(testPrefs),
            telemetryProvider.overrideWith((ref) => TestTelemetryNotifier(const TelemetryState(isLoading: true))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: JobProgressCard(),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonShimmer), findsWidgets);
    });

    testWidgets('JobProgressCard renders active print progress and metrics', (WidgetTester tester) async {
      const mockStatus = PrinterStatusData(
        printerState: 'PRINTING',
        progress: 68.5,
        currentLayer: 250,
        totalLayers: 365,
        jobName: 'gear_bearing_v2.gcode',
        timeRemaining: 1820,
        timeElapsed: 3900,
        nozzleTemperature: 215.0,
        nozzleTargetTemperature: 215.0,
        bedTemperature: 60.0,
        bedTargetTemperature: 60.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(testPrefs),
            telemetryProvider.overrideWith((ref) => TestTelemetryNotifier(const TelemetryState(isLoading: false, status: mockStatus))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: JobProgressCard(),
            ),
          ),
        ),
      );

      expect(find.text('gear_bearing_v2.gcode'), findsOneWidget);
      expect(find.text('68.5%'), findsOneWidget);
      expect(find.text('Layer 250 / 365'), findsOneWidget);
    });
  });
}
