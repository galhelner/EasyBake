import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

enum ChatEventType { textDelta, metadata, recipeCreated, error, done }

class ChatEvent {
  const ChatEvent._({
    required this.type,
    this.delta,
    this.metadata,
    this.recipe,
    this.message,
    this.isConnectionIssue = false,
  });

  const ChatEvent.textDelta(String delta)
    : this._(type: ChatEventType.textDelta, delta: delta);

  const ChatEvent.metadata(Map<String, dynamic> metadata)
    : this._(type: ChatEventType.metadata, metadata: metadata);

  const ChatEvent.recipeCreated(Map<String, dynamic> recipe)
    : this._(type: ChatEventType.recipeCreated, recipe: recipe);

  const ChatEvent.error(String message, {bool isConnectionIssue = false})
    : this._(
        type: ChatEventType.error,
        message: message,
        isConnectionIssue: isConnectionIssue,
      );

  const ChatEvent.done() : this._(type: ChatEventType.done);

  final ChatEventType type;
  final String? delta;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? recipe;
  final String? message;
  final bool isConnectionIssue;
}

class ChatService {
  ChatService(this._dio);

  final Dio _dio;

  Stream<ChatEvent> sendPrompt({
    required String prompt,
    required String pageContext,
    String? recipeId,
  }) async* {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      yield const ChatEvent.error('Please type a message first.');
      yield const ChatEvent.done();
      return;
    }

    final payload = <String, dynamic>{
      'prompt': normalizedPrompt,
      'page_context': pageContext,
      if (pageContext == 'recipe_detail' &&
          recipeId != null &&
          recipeId.trim().isNotEmpty)
        'recipe_id': recipeId.trim(),
    };

    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        '/chat',
        data: payload,
        options: Options(
          responseType: ResponseType.stream,
          headers: const {
            'Accept': 'text/event-stream, application/json',
          },
        ),
      );
    } on DioException catch (error) {
      final message = _extractFriendlyDioError(error);
      yield ChatEvent.error(
        message,
        isConnectionIssue: _isConnectionIssue(error),
      );
      yield const ChatEvent.done();
      return;
    } catch (_) {
      yield const ChatEvent.error(
        'Could not send your message. Please try again.',
        isConnectionIssue: true,
      );
      yield const ChatEvent.done();
      return;
    }

    final body = response.data;
    if (body == null) {
      yield const ChatEvent.error('Empty response from server.');
      yield const ChatEvent.done();
      return;
    }

    final contentType =
        response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';
    final isSse = contentType.contains('text/event-stream');

    if (isSse) {
      yield* _consumeSse(body.stream);
      return;
    }

    yield* _consumeJson(body.stream);
  }

  Stream<ChatEvent> _consumeSse(Stream<List<int>> source) async* {
    var buffer = '';

    try {
      await for (final chunk in source) {
        if (chunk.isEmpty) {
          continue;
        }

        buffer += utf8.decode(chunk, allowMalformed: true);

        var separatorIndex = buffer.indexOf('\n\n');
        while (separatorIndex != -1) {
          final eventBlock = buffer.substring(0, separatorIndex);
          buffer = buffer.substring(separatorIndex + 2);
          yield* _parseSseEventBlock(eventBlock);
          separatorIndex = buffer.indexOf('\n\n');
        }
      }

      if (buffer.trim().isNotEmpty) {
        yield* _parseSseEventBlock(buffer);
      }
    } catch (_) {
      yield const ChatEvent.error('Stream interrupted. Please try again.');
    }

    yield const ChatEvent.done();
  }

  Stream<ChatEvent> _parseSseEventBlock(String block) async* {
    final lines = block.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (!line.startsWith('data:')) {
        continue;
      }

      final data = line.substring(5).trim();
      if (data.isEmpty) {
        continue;
      }

      if (data == '[DONE]') {
        yield const ChatEvent.done();
        continue;
      }

      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final type = decoded['type']?.toString();
          if (type == 'error') {
            yield ChatEvent.error(
              decoded['message']?.toString() ??
                  'The assistant could not complete this response.',
            );
            continue;
          }

          if (type == 'metadata') {
            yield ChatEvent.metadata(decoded);
            continue;
          }

          final delta = decoded['delta']?.toString();
          if (delta != null && delta.isNotEmpty) {
            yield ChatEvent.textDelta(delta);
          }
        }
      } catch (_) {
        // Ignore malformed chunks and keep the stream alive.
      }
    }
  }

  Stream<ChatEvent> _consumeJson(Stream<List<int>> source) async* {
    final collected = <int>[];

    try {
      await for (final chunk in source) {
        collected.addAll(chunk);
      }
    } catch (_) {
      yield const ChatEvent.error('Could not read server response. Please try again.');
      yield const ChatEvent.done();
      return;
    }

    final text = utf8.decode(collected, allowMalformed: true).trim();
    if (text.isEmpty) {
      yield const ChatEvent.error('Empty response from server.');
      yield const ChatEvent.done();
      return;
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        if (decoded['error'] != null) {
          final rawError = decoded['error'].toString();
          yield ChatEvent.error(_toFriendlyErrorMessage(rawError));
        } else if (_looksLikeRecipe(decoded)) {
          yield ChatEvent.recipeCreated(decoded);
        } else {
          yield const ChatEvent.error('Response received in an unsupported format.');
        }
      } else {
        yield const ChatEvent.error('Unexpected response format from server.');
      }
    } catch (_) {
      yield const ChatEvent.error('Failed to parse server response.');
    }

    yield const ChatEvent.done();
  }

  bool _looksLikeRecipe(Map<String, dynamic> json) {
    return json['title'] is String &&
        json['ingredients'] is List &&
        json['instructions'] is List;
  }

  bool _isConnectionIssue(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // HTTP responses (including 5xx) indicate recipe-service is reachable.
    // Reserve "offline" for transport-level failures only.
    if (error.type == DioExceptionType.badResponse) {
      return false;
    }

    final message = error.message?.toLowerCase() ?? '';
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection');
  }

  String _extractFriendlyDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The server is taking too long to respond. Please try again in a moment.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server right now. Please check your connection and try again.';
    }

    if (error.type == DioExceptionType.cancel) {
      return 'Request was cancelled. Please try again.';
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] != null) {
      return _toFriendlyErrorMessage(
        data['error'].toString(),
        statusCode: statusCode,
      );
    }

    if (data is String && data.trim().isNotEmpty) {
      return _toFriendlyErrorMessage(data.trim(), statusCode: statusCode);
    }

    return _toFriendlyErrorMessage(
      error.message ?? 'Request failed. Please try again.',
      statusCode: statusCode,
    );
  }

  String _toFriendlyErrorMessage(String raw, {int? statusCode}) {
    final normalized = raw.toLowerCase();

    if (statusCode == 401 || statusCode == 403 || normalized.contains('unauthorized')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (statusCode == 404) {
      return 'I could not find what you requested. Please try again.';
    }

    if (statusCode == 429 ||
        normalized.contains('rate limit') ||
        normalized.contains('resource_exhausted') ||
        normalized.contains('quota')) {
      return 'I am a bit busy right now. Please try again in a few seconds.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'The server hit an issue while handling your request. Please try again shortly.';
    }

    if (normalized.contains('validation') || normalized.contains('invalid')) {
      return 'I could not process that message. Please rephrase and try again.';
    }

    return 'Something went wrong on our side. Please try again.';
  }

  Future<bool> pingService() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final status = response.data?['status']?.toString().toLowerCase();
      return status == 'ok';
    } catch (_) {
      return false;
    }
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(dioProvider));
});