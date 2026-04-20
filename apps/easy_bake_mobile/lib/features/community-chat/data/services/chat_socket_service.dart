import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../domain/models/models.dart';

typedef OnMessageCallback = void Function(ChatMessage message);
typedef OnMessageHistoryCallback = void Function(List<ChatMessage> messages);
typedef OnErrorCallback = void Function(String error);
typedef OnUserJoinedCallback = void Function(String userId, String email);
typedef OnUserLeftCallback = void Function(String userId);
typedef OnConnectionStateChangedCallback = void Function(bool isConnected);

class ChatSocketService {
  late io.Socket _socket;
  final String _serverUrl;
  final String _token;

  OnMessageCallback? onMessage;
  OnMessageHistoryCallback? onMessageHistory;
  OnErrorCallback? onError;
  OnUserJoinedCallback? onUserJoined;
  OnUserLeftCallback? onUserLeft;
  OnConnectionStateChangedCallback? onConnectionStateChanged;

  bool get isConnected => _socket.connected;

  ChatSocketService({
    required String serverUrl,
    required String token,
  })  : _serverUrl = serverUrl,
        _token = token;

  Future<void> connect() async {
    try {
      debugPrint('[Chat] Connecting to $_serverUrl');

      _socket = io.io(
        _serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
        .enableForceNew()
        .disableMultiplex()
            .disableAutoConnect()
            .setAuth({'token': _token})
            .build(),
      );

      _setupListeners();

      _socket.connect();

      // Wait for connection or timeout after 10 seconds
      await Future.delayed(const Duration(seconds: 10));
      if (!_socket.connected) {
        onConnectionStateChanged?.call(false);
        throw Exception('Failed to connect to chat server');
      }

      onConnectionStateChanged?.call(true);
      debugPrint('[Chat] Connected successfully');
    } catch (e) {
      debugPrint('[Chat] Connection error: $e');
      onConnectionStateChanged?.call(false);
      onError?.call('Connection failed: $e');
      rethrow;
    }
  }

  void _setupListeners() {
    _socket.on('connect', (_) {
      debugPrint('[Chat] Socket connected');
      onConnectionStateChanged?.call(true);
    });

    _socket.on('message_history', (data) {
      try {
        debugPrint('[Chat] Received message history: ${data.length} messages');
        final messages = (data as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        onMessageHistory?.call(messages);
      } catch (e) {
        debugPrint('[Chat] Error parsing message history: $e');
        onError?.call('Failed to load message history');
      }
    });

    _socket.on('new_message', (data) {
      try {
        final message = ChatMessage.fromJson(data as Map<String, dynamic>);
        debugPrint('[Chat] Received new message: ${message.id}');
        onMessage?.call(message);
      } catch (e) {
        debugPrint('[Chat] Error parsing message: $e');
        onError?.call('Failed to receive message');
      }
    });

    _socket.on('user_joined', (data) {
      try {
        final userId = data['userId'] as String;
        final email = data['email'] as String?;
        debugPrint('[Chat] User joined: $userId');
        onUserJoined?.call(userId, email ?? '');
      } catch (e) {
        debugPrint('[Chat] Error parsing user_joined: $e');
      }
    });

    _socket.on('user_left', (data) {
      try {
        final userId = data['userId'] as String;
        debugPrint('[Chat] User left: $userId');
        onUserLeft?.call(userId);
      } catch (e) {
        debugPrint('[Chat] Error parsing user_left: $e');
      }
    });

    _socket.on('error', (data) {
      final message = data is Map ? data['message'] as String? : data.toString();
      debugPrint('[Chat] Socket error: $message');
      onError?.call(message ?? 'Unknown error');
    });

    _socket.on('disconnect', (_) {
      debugPrint('[Chat] Socket disconnected');
      onConnectionStateChanged?.call(false);
    });

    _socket.onConnectError((data) {
      debugPrint('[Chat] Connection error: $data');
      onConnectionStateChanged?.call(false);
      onError?.call('Connection error: $data');
    });
  }

  bool sendMessage(String content) {
    if (!_socket.connected) {
      onError?.call('Not connected to chat server');
      return false;
    }

    try {
      debugPrint('[Chat] Sending message: $content');
      _socket.emit('send_message', {'content': content});
      return true;
    } catch (e) {
      debugPrint('[Chat] Error sending message: $e');
      onError?.call('Failed to send message');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      debugPrint('[Chat] Disconnecting');
      _socket.disconnect();
      _socket.dispose();
      onConnectionStateChanged?.call(false);
      debugPrint('[Chat] Disconnected');
    } catch (e) {
      debugPrint('[Chat] Error disconnecting: $e');
    }
  }
}
