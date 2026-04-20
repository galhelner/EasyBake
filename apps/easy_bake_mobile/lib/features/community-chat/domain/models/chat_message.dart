enum ChatMessageDeliveryStatus {
  pending,
  sent,
}

class ChatMessage {
  final String id;
  final String userId;
  final String userEmail;
  final String? userFullName;
  final String content;
  final DateTime createdAt;
  final String? localId;
  final ChatMessageDeliveryStatus? deliveryStatus;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    required this.content,
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
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: localId,
      userId: userId,
      userEmail: userEmail,
      userFullName: userFullName,
      content: content,
      createdAt: createdAt,
      localId: localId,
      deliveryStatus: ChatMessageDeliveryStatus.pending,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userEmail: json['userEmail'] as String? ?? '',
      userFullName: json['userFullName'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userEmail': userEmail,
    'userFullName': userFullName,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  String toString() =>
      'ChatMessage(id: $id, userId: $userId, content: $content, createdAt: $createdAt, deliveryStatus: $deliveryStatus)';
}
