class ShoppingListIngredientModel {
  const ShoppingListIngredientModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final String icon;

  factory ShoppingListIngredientModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListIngredientModel(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      icon: (json['icon'] as String? ?? '').trim(),
    );
  }
}

class ShoppingListItemModel {
  const ShoppingListItemModel({
    required this.id,
    required this.checked,
    required this.ingredient,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final bool checked;
  final ShoppingListIngredientModel ingredient;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    final ingredientJson = json['ingredient'];
    final ingredient = ingredientJson is Map<String, dynamic>
        ? ShoppingListIngredientModel.fromJson(ingredientJson)
        : const ShoppingListIngredientModel(id: '', name: '', icon: '');

    return ShoppingListItemModel(
      id: (json['id'] as String? ?? '').trim(),
      checked: json['checked'] as bool? ?? false,
      ingredient: ingredient,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  ShoppingListItemModel copyWith({
    String? id,
    bool? checked,
    ShoppingListIngredientModel? ingredient,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingListItemModel(
      id: id ?? this.id,
      checked: checked ?? this.checked,
      ingredient: ingredient ?? this.ingredient,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
