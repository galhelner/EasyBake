class IngredientSuggestionModel {
  const IngredientSuggestionModel({required this.name, required this.icon});

  final String name;
  final String icon;

  factory IngredientSuggestionModel.fromJson(Map<String, dynamic> json) {
    return IngredientSuggestionModel(
      name: (json['name'] as String? ?? '').trim(),
      icon: (json['icon'] as String? ?? '').trim(),
    );
  }
}
