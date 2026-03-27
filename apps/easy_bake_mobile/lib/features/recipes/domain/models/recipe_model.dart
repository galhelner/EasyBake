class RecipeModel {
  final String? id;
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final int healthScore;
  final String? imageUrl;
  final String? authorId;

  RecipeModel({
    this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.healthScore,
    this.imageUrl,
    this.authorId,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final instructionsValue = json['instructions'];
    final instructionsList = _parseInstructions(instructionsValue);

    final ingredientsValue = json['ingredients'];
    final ingredientsList = _parseIngredients(ingredientsValue);

    return RecipeModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'New Recipe',
      ingredients: ingredientsList,
      instructions: instructionsList,
      healthScore:
          (json['healthScore'] as int?) ?? (json['health_score'] as int?) ?? 5,
      imageUrl: json['imageUrl'] as String?,
      authorId: json['authorId'] as String?,
    );
  }

  static List<String> _parseInstructions(dynamic value) {
    if (value is String) {
      return value
          .split(RegExp(r"\r?\n"))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [];
  }

  static List<String> _parseIngredients(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) {
          if (item is Map<String, dynamic>) {
            final name = item['name'];
            return name?.toString();
          }
          return item?.toString();
        })
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'instructions': instructions.join('\n'),
      'healthScore': healthScore,
      'ingredients': ingredients.map((name) => {'name': name}).toList(),
    };
  }
}
