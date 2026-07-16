import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

enum ChatEventType {
  textDelta,
  metadata,
  intentDetected,
  recipeCreated,
  searchResults,
  shoppingListAdded,
  error,
  done,
}

enum ChatErrorKind {
  emptyPrompt,
  sendFailed,
  emptyResponse,
  streamInterrupted,
  assistantCouldNotComplete,
  couldNotReadServerResponse,
  responseUnsupportedFormat,
  unexpectedResponseFormat,
  failedToParseServerResponse,
  requestFailed,
  serverSlow,
  cannotReachServer,
  requestCancelled,
  unauthorized,
  serverIssue,
  notFound,
  rateLimited,
  validation,
  generic,
}

class ChatEvent {
  const ChatEvent._({
    required this.type,
    this.delta,
    this.intent,
    this.metadata,
    this.recipe,
    this.searchResults,
    this.shoppingListItems,
    this.errorKind,
    this.isConnectionIssue = false,
  });

  const ChatEvent.textDelta(String delta)
    : this._(type: ChatEventType.textDelta, delta: delta);

  const ChatEvent.intentDetected(String intent)
    : this._(type: ChatEventType.intentDetected, intent: intent);

  const ChatEvent.metadata(Map<String, dynamic> metadata)
    : this._(type: ChatEventType.metadata, metadata: metadata);

  const ChatEvent.recipeCreated(Map<String, dynamic> recipe)
    : this._(type: ChatEventType.recipeCreated, recipe: recipe);

  const ChatEvent.searchResults(List<dynamic> results)
    : this._(type: ChatEventType.searchResults, searchResults: results);

  const ChatEvent.shoppingListAdded(List<dynamic> items)
    : this._(type: ChatEventType.shoppingListAdded, shoppingListItems: items);

  const ChatEvent.error(
    ChatErrorKind errorKind, {
    bool isConnectionIssue = false,
  })
    : this._(
        type: ChatEventType.error,
        errorKind: errorKind,
        isConnectionIssue: isConnectionIssue,
      );

  const ChatEvent.done() : this._(type: ChatEventType.done);

  final ChatEventType type;
  final String? delta;
  final String? intent;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? recipe;
  final List<dynamic>? searchResults;
  final List<dynamic>? shoppingListItems;
  final ChatErrorKind? errorKind;
  final bool isConnectionIssue;
}

class ChatService {
  ChatService(this._dio);

  final Dio _dio;
  static const _chatConnectTimeout = Duration(seconds: 45);
  static const _chatSendTimeout = Duration(seconds: 45);
  static const _chatReceiveTimeout = Duration(seconds: 180);

  Stream<ChatEvent> sendPrompt({
    required String prompt,
    required String pageContext,
    required String sessionId,
    String? recipeId,
  }) async* {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      yield const ChatEvent.error(ChatErrorKind.emptyPrompt);
      yield const ChatEvent.done();
      return;
    }

    final payload = <String, dynamic>{
      'prompt': normalizedPrompt,
      'page_context': pageContext,
      'session_id': sessionId,
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
          connectTimeout: _chatConnectTimeout,
          sendTimeout: _chatSendTimeout,
          receiveTimeout: _chatReceiveTimeout,
          headers: const {'Accept': 'text/event-stream, application/json'},
        ),
      );
    } on DioException catch (error) {
      yield ChatEvent.error(
        _errorKindFromDioError(error),
        isConnectionIssue: _isConnectionIssue(error),
      );
      yield const ChatEvent.done();
      return;
    } catch (_) {
      yield const ChatEvent.error(ChatErrorKind.sendFailed, isConnectionIssue: true);
      yield const ChatEvent.done();
      return;
    }

    final body = response.data;
    if (body == null) {
      yield const ChatEvent.error(ChatErrorKind.emptyResponse);
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
      yield const ChatEvent.error(ChatErrorKind.streamInterrupted);
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
              _errorKindFromServerError(decoded['message']?.toString()),
            );
            continue;
          }

          if (type == 'metadata') {
            yield ChatEvent.metadata(decoded);
            continue;
          }

          if (type == 'intent') {
            final intent = decoded['intent']?.toString();
            if (intent != null && intent.isNotEmpty) {
              yield ChatEvent.intentDetected(intent);
            }
            continue;
          }

          if (type == 'recipeCreated') {
            final recipe = decoded['recipe'];
            if (recipe is Map<String, dynamic>) {
              yield ChatEvent.recipeCreated(recipe);
            }
            continue;
          }

          if (type == 'searchResults') {
            final recipes = decoded['recipes'];
            if (recipes is List) {
              yield ChatEvent.searchResults(recipes);
            }
            continue;
          }

          if (type == 'shoppingListAdded') {
            final items = decoded['items'];
            if (items is List) {
              yield ChatEvent.shoppingListAdded(items);
            }
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
      yield const ChatEvent.error(ChatErrorKind.couldNotReadServerResponse);
      yield const ChatEvent.done();
      return;
    }

    final text = utf8.decode(collected, allowMalformed: true).trim();
    if (text.isEmpty) {
      yield const ChatEvent.error(ChatErrorKind.emptyResponse);
      yield const ChatEvent.done();
      return;
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        if (decoded['error'] != null) {
          final rawError = decoded['error'].toString();
          yield ChatEvent.error(_errorKindFromRawError(rawError));
        } else if (_looksLikeRecipe(decoded)) {
          yield ChatEvent.recipeCreated(decoded);
        } else {
          yield const ChatEvent.error(ChatErrorKind.responseUnsupportedFormat);
        }
      } else {
        yield const ChatEvent.error(ChatErrorKind.unexpectedResponseFormat);
      }
    } catch (_) {
      yield const ChatEvent.error(ChatErrorKind.failedToParseServerResponse);
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

  ChatErrorKind _errorKindFromDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ChatErrorKind.serverSlow;
    }

    if (error.type == DioExceptionType.connectionError) {
      return ChatErrorKind.cannotReachServer;
    }

    if (error.type == DioExceptionType.cancel) {
      return ChatErrorKind.requestCancelled;
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] != null) {
      return _errorKindFromRawError(
        data['error'].toString(),
        statusCode: statusCode,
      );
    }

    if (data is String && data.trim().isNotEmpty) {
      return _errorKindFromRawError(data.trim(), statusCode: statusCode);
    }

    return _errorKindFromRawError(
      error.message ?? 'Request failed. Please try again.',
      statusCode: statusCode,
    );
  }

  ChatErrorKind _errorKindFromServerError(String? raw) {
    final normalized = raw?.toLowerCase() ?? '';

    if (normalized.contains('could not complete')) {
      return ChatErrorKind.assistantCouldNotComplete;
    }

    return ChatErrorKind.generic;
  }

  ChatErrorKind _errorKindFromRawError(String raw, {int? statusCode}) {
    final normalized = raw.toLowerCase();

    if (statusCode == 401 || normalized.contains('unauthorized')) {
      return ChatErrorKind.unauthorized;
    }

    if (statusCode == 403) {
      return ChatErrorKind.serverIssue;
    }

    if (statusCode == 404) {
      return ChatErrorKind.notFound;
    }

    if (statusCode == 429 ||
        normalized.contains('rate limit') ||
        normalized.contains('resource_exhausted') ||
        normalized.contains('quota')) {
        return ChatErrorKind.rateLimited;
    }

    if (statusCode != null && statusCode >= 500) {
        return ChatErrorKind.serverIssue;
    }

    if (normalized.contains('validation') || normalized.contains('invalid')) {
        return ChatErrorKind.validation;
    }

      if (normalized.contains('request failed')) {
        return ChatErrorKind.requestFailed;
      }

      if (normalized.contains('could not read server response')) {
        return ChatErrorKind.couldNotReadServerResponse;
      }

      if (normalized.contains('failed to parse')) {
        return ChatErrorKind.failedToParseServerResponse;
      }

      return ChatErrorKind.generic;
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

  Future<List<Map<String, dynamic>>> getChatHistory({
    required String pageContext,
    String? recipeId,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/chat/history',
        queryParameters: {
          'pageContext': pageContext,
          if (recipeId != null && recipeId.trim().isNotEmpty)
            'recipeId': recipeId.trim(),
        },
      );
      if (response.data != null) {
        return response.data!
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<bool> clearChatHistory({
    required String pageContext,
    String? recipeId,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/chat/history',
        queryParameters: {
          'pageContext': pageContext,
          if (recipeId != null && recipeId.trim().isNotEmpty)
            'recipeId': recipeId.trim(),
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(dioProvider));
});
