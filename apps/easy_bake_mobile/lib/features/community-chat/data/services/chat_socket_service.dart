import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';

import '../../domain/models/models.dart';

typedef OnMessageCallback = void Function(ChatMessage message);
typedef OnMessageHistoryCallback = void Function(List<ChatMessage> messages);
typedef OnErrorCallback = void Function(String error);
typedef OnUserJoinedCallback = void Function(String userId, String email);
typedef OnUserLeftCallback = void Function(String userId);
typedef OnConnectionStateChangedCallback = void Function(bool isConnected);

class ChatSocketService {
  static const _unavailableMessage =
      'Community chat is temporarily unavailable. Please refresh or try again later.';
  static const _sendFailedMessage =
      'Could not send your message right now. Please try again later.';

  late io.Socket _socket;
  final String _serverUrl;
  final String _token;
  Completer<void>? _connectCompleter;

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

      // Create a completer to wait for actual connection
      _connectCompleter = Completer<void>();

      _socket.connect();

      // Wait for connection with 10-second timeout
      try {
        await _connectCompleter!.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Socket connection timeout');
          },
        );
      } finally {
        _connectCompleter = null;
      }

      debugPrint('[Chat] Connected successfully');
    } catch (e) {
      debugPrint('[Chat] Connection error: $e');
      onConnectionStateChanged?.call(false);
      onError?.call(_unavailableMessage);
      rethrow;
    }
  }

  void _setupListeners() {
    _socket.on('connect', (_) {
      debugPrint('[Chat] Socket connected');
      onConnectionStateChanged?.call(true);
      // Complete the connection future if waiting
      _connectCompleter?.complete();
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
        onError?.call(_unavailableMessage);
      }
    });

    _socket.on('new_message', (data) {
      try {
        final message = ChatMessage.fromJson(data as Map<String, dynamic>);
        debugPrint('[Chat] Received new message: ${message.id}');
        onMessage?.call(message);
      } catch (e) {
        debugPrint('[Chat] Error parsing message: $e');
        onError?.call(_unavailableMessage);
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
      onConnectionStateChanged?.call(false);
      onError?.call(_unavailableMessage);
    });

    _socket.on('disconnect', (_) {
      debugPrint('[Chat] Socket disconnected');
      onConnectionStateChanged?.call(false);
    });

    _socket.onConnectError((data) {
      debugPrint('[Chat] Connection error: $data');
      onConnectionStateChanged?.call(false);
      onError?.call(_unavailableMessage);
      // Fail the completer if still waiting
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.completeError('Connection error: $data');
      }
    });
  }

  bool sendMessage(String content) {
    if (!_socket.connected) {
      onConnectionStateChanged?.call(false);
      onError?.call('Not connected to chat server');
      return false;
    }

    try {
      debugPrint('[Chat] Sending message: $content');
      _socket.emit('send_message', {'content': content});
      return true;
    } catch (e) {
      debugPrint('[Chat] Error sending message: $e');
      onConnectionStateChanged?.call(false);
      onError?.call(_sendFailedMessage);
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
