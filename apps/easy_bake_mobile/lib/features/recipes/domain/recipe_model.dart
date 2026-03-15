class RecipeModel {
  final String? id;
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final int healthScore;
  final String? authorId;

  RecipeModel({
    this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.healthScore,
    this.authorId,
  });

  /// Convert from the recipe-service response.
  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final instructionsRaw = json['instructions'] as String? ?? '';
    final instructionsList = instructionsRaw
        .split(RegExp(r"\r?\n"))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final ingredientsJson = json['ingredients'] as List<dynamic>?;
    final ingredientsList = ingredientsJson
            ?.map((item) => (item as Map<String, dynamic>)['name'] as String)
            .toList() ??
        [];

    return RecipeModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'New Recipe',
      ingredients: ingredientsList,
      instructions: instructionsList,
      healthScore: (json['healthScore'] as int?) ??
          (json['health_score'] as int?) ??
          5,
      authorId: json['authorId'] as String?,
    );
  }

  /// A JSON payload suitable for the recipe-service "create recipe" endpoint.
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'instructions': instructions.join('\n'),
      'healthScore': healthScore,
      'ingredients': ingredients.map((name) => {'name': name}).toList(),
    };
  }
}
