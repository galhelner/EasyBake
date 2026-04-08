class RecipeModel {
  final String? id;
  final String title;
  final List<String> ingredients;
  final Map<String, String> ingredientIcons;
  final Map<String, String> ingredientAmounts;
  final List<String> instructions;
  final int healthScore;
  final String? imageUrl;
  final String? authorId;

  RecipeModel({
    this.id,
    required this.title,
    required this.ingredients,
    Map<String, String>? ingredientIcons,
    Map<String, String>? ingredientAmounts,
    required this.instructions,
    required this.healthScore,
    this.imageUrl,
    this.authorId,
  }) : ingredientIcons = ingredientIcons ?? const {},
       ingredientAmounts = ingredientAmounts ?? const {};

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final instructionsValue = json['instructions'];
    final instructionsList = _parseInstructions(instructionsValue);

    final ingredientsValue = json['ingredients'];
    final ingredientsList = _parseIngredients(ingredientsValue);
    final ingredientIcons = _parseIngredientIcons(ingredientsValue);
    final ingredientAmounts = _parseIngredientAmounts(ingredientsValue);

    return RecipeModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'New Recipe',
      ingredients: ingredientsList,
      ingredientIcons: ingredientIcons,
      ingredientAmounts: ingredientAmounts,
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

  static Map<String, String> _parseIngredientAmounts(dynamic value) {
    if (value is! List) {
      return const {};
    }

    final result = <String, String>{};
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        final rawName = item['name']?.toString().trim() ?? '';
        final rawAmount = item['amount']?.toString().trim() ?? '';
        if (rawName.isEmpty || rawAmount.isEmpty) {
          continue;
        }
        result[rawName] = rawAmount;
      }
    }

    return result;
  }

  static Map<String, String> _parseIngredientIcons(dynamic value) {
    if (value is! List) {
      return const {};
    }

    final result = <String, String>{};
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        final rawName = item['name']?.toString().trim() ?? '';
        final rawIcon = item['icon']?.toString().trim() ?? '';
        if (rawName.isEmpty || rawIcon.isEmpty) {
          continue;
        }
        result[rawName] = rawIcon;
      }
    }

    return result;
  }

  Map<String, dynamic> toCreateJson() {
    final payloadIngredients = ingredients.map((name) {
      final normalizedName = name.trim();
      final rawAmount = ingredientAmounts[normalizedName];
      final amount = rawAmount?.trim();

      return {
        'name': normalizedName,
        if (amount != null && amount.isNotEmpty) 'amount': amount,
      };
    }).toList();

    return {
      'title': title,
      'instructions': instructions,
      'ingredients': payloadIngredients,
    };
  }
}
