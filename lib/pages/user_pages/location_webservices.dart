import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class LocationWebSocketService {
  static LocationWebSocketService? _instance;
  static LocationWebSocketService get instance {
    _instance ??= LocationWebSocketService._();
    return _instance!;
  }

  LocationWebSocketService._();

  WebSocketChannel? _channel;
  String? _userId;
  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  // Stream controllers for different message types
  final StreamController<Map<String, dynamic>> _locationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get locationUpdates =>
      _locationUpdateController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect(String userId, {String? baseUrl}) async {
    if (_isConnected && _userId == userId) {
      debugPrint('Already connected to WebSocket for user: $userId');
      return;
    }

    await disconnect();

    _userId = userId;
    final wsUrl =
        baseUrl ??
        'ws://9626-197-136-185-70.ngrok-free.app'; // Replace with your actual WebSocket URL
    final uri = '$wsUrl/ws/location/$userId';

    try {
      debugPrint('Connecting to WebSocket: $uri');
      _channel = IOWebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
      _startHeartbeat();

      debugPrint('WebSocket connected successfully for user: $userId');
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      _handleError(e);
    }
  }

  Future<void> disconnect() async {
    debugPrint('Disconnecting WebSocket');

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _connectionStatusController.add(false);
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final messageType = data['type'];

      debugPrint('Received WebSocket message: $messageType');

      switch (messageType) {
        case 'connection_established':
          debugPrint('WebSocket connection established');
          break;

        case 'location_update':
          _locationUpdateController.add(data);
          break;

        case 'tracking_started':
          debugPrint('Started tracking user: ${data["tracked_user_id"]}');
          break;

        case 'tracking_stopped':
          debugPrint('Stopped tracking user: ${data["tracked_user_id"]}');
          break;

        case 'pong':
          // Heartbeat response - connection is alive
          break;

        default:
          debugPrint('Unknown message type: $messageType');
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add(false);

    if (_reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      debugPrint('Max reconnection attempts reached');
    }
  }

  void _handleDisconnection() {
    debugPrint('WebSocket disconnected');
    _isConnected = false;
    _connectionStatusController.add(false);

    if (_reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(
      seconds: _reconnectAttempts * 2,
    ); // Exponential backoff

    debugPrint(
      'Scheduling reconnection in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(delay, () {
      if (_userId != null) {
        connect(_userId!);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        debugPrint('Error sending WebSocket message: $e');
      }
    } else {
      debugPrint('Cannot send message: WebSocket not connected');
    }
  }

  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    required int activityId,
  }) {
    sendMessage({
      'type': 'location_update',
      'data': {
        'latitude': latitude,
        'longitude': longitude,
        'activity_id': activityId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
  }

  void startTrackingUser(String trackedUserId) {
    sendMessage({'type': 'start_tracking', 'tracked_user_id': trackedUserId});
  }

  void stopTrackingUser(String trackedUserId) {
    sendMessage({'type': 'stop_tracking', 'tracked_user_id': trackedUserId});
  }

  void dispose() {
    _locationUpdateController.close();
    _connectionStatusController.close();
    disconnect();
  }
}
