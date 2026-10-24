import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

enum CameraPlayState { idle, connecting, streaming, paused, busy, offline }

class CameraStreamService extends ChangeNotifier {
  final ApiClient apiClient;
  final RTCVideoRenderer renderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  WebSocketChannel? _signalingChannel;
  StreamSubscription? _signalingSubscription;

  CameraPlayState state = CameraPlayState.idle;
  String? concurrencyNotice;
  int remainingSeconds = 30;
  bool continuousOverride = false;

  Timer? _healthCheckTimer;
  Timer? _countdownTimer;
  bool _framesVerified = false;

  CameraStreamService({required this.apiClient});

  Future<void> initRenderer() async {
    await renderer.initialize();
  }

  void showConnectingState() {
    _teardownActiveConnection();
    state = CameraPlayState.connecting;
    notifyListeners();
  }

  Future<void> startStream({String? contextId}) async {
    _teardownActiveConnection();
    state = CameraPlayState.connecting;
    _framesVerified = false;
    notifyListeners();

    try {
      final query = contextId != null ? {'contextId': contextId} : <String, dynamic>{};
      final response = await apiClient.get(ApiEndpoints.cameraProxyConfig, queryParameters: query);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true || data['wsUrl'] == null) {
        state = CameraPlayState.offline;
        notifyListeners();
        return;
      }

      concurrencyNotice = data['concurrencyNotice'] as String?;
      final String relativeWsUrl = data['wsUrl'] as String;
      final String fullWsUrl = apiClient.buildWebSocketUrl(relativeWsUrl);

      // 1. Create PeerConnection
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': ['stun:stun.cloudflare.com:3478', 'stun:stun.l.google.com:19302']}
        ],
        'sdpSemantics': 'unified-plan',
      });

      // 2. Add recvonly video transceiver so SDP offer requests video
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // 3. Connect go2rtc WebSocket signaling channel
      _signalingChannel = WebSocketChannel.connect(Uri.parse(fullWsUrl));

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
          _signalingChannel?.sink.add(jsonEncode({
            'type': 'webrtc/candidate',
            'value': candidate.candidate,
          }));
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          renderer.srcObject = event.streams.first;
          _markStreamLive();
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState pcState) {
        if (pcState == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            pcState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          if (!_framesVerified) {
            _triggerBusyState();
          }
        }
      };

      _signalingSubscription = _signalingChannel!.stream.listen(
        (dynamic message) async {
          if (message is! String) return;
          try {
            final Map<String, dynamic> msg = jsonDecode(message);
            final String? type = msg['type'] as String?;

            if (type == 'webrtc/answer') {
              final String sdp = msg['value'] as String;
              await _peerConnection?.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
            } else if (type == 'webrtc/candidate') {
              final String candidateStr = msg['value'] as String;
              if (candidateStr.isNotEmpty) {
                await _peerConnection?.addCandidate(RTCIceCandidate(candidateStr, '0', 0));
              }
            } else if (type == 'error') {
              _triggerBusyState();
            }
          } catch (e) {
            debugPrint('[CameraSignaling] Error parsing message: $e');
          }
        },
        onError: (_) => _triggerBusyState(),
      );

      // 4. Create & send SDP Offer
      final RTCSessionDescription offer = await _peerConnection!.createOffer({});
      await _peerConnection!.setLocalDescription(offer);
      _signalingChannel!.sink.add(jsonEncode({
        'type': 'webrtc/offer',
        'value': offer.sdp,
      }));

      // 5. Start 5-second health check timer (detects single-client lock by Flash Studio)
      _healthCheckTimer = Timer(const Duration(seconds: 5), () {
        if (!_framesVerified) {
          _triggerBusyState();
        }
      });
    } catch (e) {
      debugPrint('[CameraStream] Stream creation failed: $e');
      _triggerBusyState();
    }
  }

  void _markStreamLive() {
    if (_framesVerified) return;
    _framesVerified = true;
    _healthCheckTimer?.cancel();
    state = CameraPlayState.streaming;
    _startStreamCountdown();
    notifyListeners();
  }

  void _triggerBusyState() {
    _teardownActiveConnection();
    state = CameraPlayState.busy;
    notifyListeners();
  }

  void pauseStream({bool dueToTimeout = false}) {
    _teardownActiveConnection();
    state = CameraPlayState.paused;
    notifyListeners();
  }

  void setContinuousOverride(bool override) {
    continuousOverride = override;
    if (state == CameraPlayState.streaming) {
      if (continuousOverride) {
        _countdownTimer?.cancel();
      } else {
        _startStreamCountdown();
      }
    }
    notifyListeners();
  }

  void _startStreamCountdown() {
    _countdownTimer?.cancel();
    if (continuousOverride) return;

    remainingSeconds = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds -= 1;
      if (remainingSeconds <= 0) {
        pauseStream(dueToTimeout: true);
      } else {
        notifyListeners();
      }
    });
  }

  void _teardownActiveConnection() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _signalingSubscription?.cancel();
    _signalingSubscription = null;
    _signalingChannel?.sink.close();
    _signalingChannel = null;
    renderer.srcObject = null;
    _peerConnection?.close();
    _peerConnection = null;
  }

  @override
  void dispose() {
    _teardownActiveConnection();
    renderer.dispose();
    super.dispose();
  }
}
