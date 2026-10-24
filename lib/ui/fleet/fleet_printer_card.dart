import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../models/printer_context.dart';
import '../../services/camera_stream_service.dart';
import '../../state/auth_provider.dart';
import '../../state/fleet_provider.dart';
import '../common/status_badge.dart';

class FleetPrinterCard extends ConsumerStatefulWidget {
  final FleetOverviewPrinter printer;
  final VoidCallback onTap;

  const FleetPrinterCard({
    super.key,
    required this.printer,
    required this.onTap,
  });

  @override
  ConsumerState<FleetPrinterCard> createState() => _FleetPrinterCardState();
}

class _FleetPrinterCardState extends ConsumerState<FleetPrinterCard> {
  CameraStreamService? _cardCamera;
  bool _isPlaying = false;

  void _onCameraChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cardCamera?.removeListener(_onCameraChanged);
    _cardCamera?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _cardCamera?.pauseStream();
      setState(() => _isPlaying = false);
    } else {
      if (_cardCamera == null) {
        final apiClient = ref.read(apiClientProvider);
        _cardCamera = CameraStreamService(apiClient: apiClient);
        _cardCamera!.addListener(_onCameraChanged);
        _cardCamera!.initRenderer().then((_) {
          if (mounted) {
            _cardCamera!.startStream(contextId: widget.printer.contextId);
            setState(() => _isPlaying = true);
          }
        });
      } else {
        _cardCamera!.startStream(contextId: widget.printer.contextId);
        setState(() => _isPlaying = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.printer;
    final isPrinting = p.statusText.toLowerCase().contains('print') || p.statusText.toLowerCase().contains('busy');
    final isCompleted = p.statusText.toLowerCase().contains('complete') || (p.progress >= 100 && !isPrinting && p.jobName != null);
    final cardCameraState = _cardCamera?.state ?? CameraPlayState.idle;
    final fleetErrors = ref.watch(fleetProvider).cameraErrors;
    final hasCameraError = cardCameraState == CameraPlayState.busy || fleetErrors.containsKey(p.name);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Camera Box Stage
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    // Video / MJPEG View
                    if (_isPlaying && cardCameraState == CameraPlayState.streaming && _cardCamera != null)
                      _cardCamera!.lastJpegBytes != null
                          ? Image.memory(
                              _cardCamera!.lastJpegBytes!,
                              gaplessPlayback: true,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : RTCVideoView(
                              _cardCamera!.renderer,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                            ),

                    // Connecting Spinner
                    if (_isPlaying && cardCameraState == CameraPlayState.connecting)
                      const Center(child: CircularProgressIndicator(color: AppColors.accentGreen, strokeWidth: 2)),

                    // Busy / Offline Notice
                    if (hasCameraError)
                      Container(
                        color: Colors.black.withValues(alpha: 0.9),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.videoOff, size: 16, color: AppColors.warning),
                                const SizedBox(height: 2),
                                const Text(
                                  'Camera In Use / Offline',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.warningLight, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  p.model.toLowerCase().contains('creator') || p.model.toLowerCase().contains('5m')
                                      ? 'May be open in Flash Studio or another app'
                                      : 'May be open in another viewer',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
                                ),
                                const SizedBox(height: 3),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warning,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    ref.read(fleetProvider.notifier).clearCardCameraError(p.name);
                                    _cardCamera?.startStream(contextId: p.contextId);
                                  },
                                  child: const Text('Retry', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Standby Overlay (Default on page open)
                    if (!_isPlaying && !hasCameraError)
                      Container(
                        color: Colors.black.withValues(alpha: 0.8),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.video, size: 22, color: AppColors.accentGreen),
                              const SizedBox(height: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: _togglePlay,
                                icon: const Icon(LucideIcons.play, size: 12),
                                label: const Text('Watch Stream', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Play/Pause Floating Icon in corner when streaming
                    if (_isPlaying && cardCameraState == CameraPlayState.streaming)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(LucideIcons.pause, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Card Body (Telemetry summary)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(
                        statusText: p.statusText,
                        isPrinting: isPrinting,
                        isCompleted: isCompleted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (p.jobName != null && p.jobName!.isNotEmpty) ...[
                    Text(
                      p.jobName!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (p.progress / 100.0).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? AppColors.info : AppColors.accentGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${p.progress.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('L ${p.currentLayer}/${p.totalLayers}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ] else ...[
                    const Text('Idle / No active job', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nozzle: ${p.nozzleTemp.toStringAsFixed(0)}\u00B0C',
                          style: const TextStyle(fontSize: 10, color: AppColors.toolheadT0)),
                      Text('Bed: ${p.bedTemp.toStringAsFixed(0)}\u00B0C',
                          style: const TextStyle(fontSize: 10, color: AppColors.bedHeat)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
