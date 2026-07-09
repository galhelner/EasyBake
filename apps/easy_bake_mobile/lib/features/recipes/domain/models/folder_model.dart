class FolderModel {
  final String id;
  final String name;
  final String userId;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderModel({
    required this.id,
    required this.name,
    required this.userId,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      parentId: json['parentId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
