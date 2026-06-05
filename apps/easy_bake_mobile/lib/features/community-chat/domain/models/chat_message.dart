enum ChatMessageDeliveryStatus { pending, sent }

enum ChatMessageType { text, recipe, aiAssistant }

ChatMessageType _parseChatMessageType(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'recipe':
      return ChatMessageType.recipe;
    case 'ai-assistant':
    case 'aiassistant':
      return ChatMessageType.aiAssistant;
    case 'text':
    default:
      return ChatMessageType.text;
  }
}

String _serializeChatMessageType(ChatMessageType type) {
  switch (type) {
    case ChatMessageType.recipe:
      return 'recipe';
    case ChatMessageType.aiAssistant:
      return 'ai-assistant';
    case ChatMessageType.text:
      return 'text';
  }
}

class ChatMessage {
  final String id;
  final String userId;
  final String userEmail;
  final String? userFullName;
  final String content;
  final ChatMessageType type;
  final String? recipeId;
  final DateTime createdAt;
  final String? localId;
  final ChatMessageDeliveryStatus? deliveryStatus;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    required this.content,
    this.type = ChatMessageType.text,
    this.recipeId,
    required this.createdAt,
    this.localId,
    this.deliveryStatus,
  });

  bool get isPending => deliveryStatus == ChatMessageDeliveryStatus.pending;

  ChatMessage copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userFullName,
    String? content,
    ChatMessageType? type,
    String? recipeId,
    DateTime? createdAt,
    String? localId,
    ChatMessageDeliveryStatus? deliveryStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userFullName: userFullName ?? this.userFullName,
      content: content ?? this.content,
      type: type ?? this.type,
      recipeId: recipeId ?? this.recipeId,
      createdAt: createdAt ?? this.createdAt,
      localId: localId ?? this.localId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }

  factory ChatMessage.pending({
    required String localId,
    required String userId,
    required String userEmail,
    required String? userFullName,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    String? recipeId,
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: localId,
      userId: userId,
      userEmail: userEmail,
      userFullName: userFullName,
      content: content,
      type: type,
      recipeId: recipeId,
      createdAt: createdAt,
      localId: localId,
      deliveryStatus: ChatMessageDeliveryStatus.pending,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: (json['userId'] as String?) ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      userFullName:
          (json['userDisplayName'] as String?) ??
          (json['userFullName'] as String?),
      content: json['content'] as String,
      type: _parseChatMessageType(json['messageType'] as String?),
      recipeId: json['recipeId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userEmail': userEmail,
    'userFullName': userFullName,
    'content': content,
    'messageType': _serializeChatMessageType(type),
    'recipeId': recipeId,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  String toString() =>
      'ChatMessage(id: $id, userId: $userId, content: $content, createdAt: $createdAt, deliveryStatus: $deliveryStatus)';
}
