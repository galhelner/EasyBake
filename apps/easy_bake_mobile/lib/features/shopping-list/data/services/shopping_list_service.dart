import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/shopping_list_item_model.dart';

class ShoppingListService {
  ShoppingListService(this._dio);

  final Dio _dio;

  Future<List<ShoppingListItemModel>> fetchShoppingList({
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get('/shopping-list', cancelToken: cancelToken);
    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) =>
              ShoppingListItemModel.fromJson(item as Map<String, dynamic>),
        )
        .where((item) => item.id.isNotEmpty && item.ingredient.name.isNotEmpty)
        .toList();
  }

  Future<ShoppingListItemModel> addShoppingListItem({
    required String ingredientName,
    String? amount,
    bool checked = false,
  }) async {
    final response = await _dio.post(
      '/shopping-list',
      data: {
        'ingredientName': ingredientName,
        'checked': checked,
        'amount': ?amount,
      },
    );

    return ShoppingListItemModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ShoppingListItemModel> updateShoppingListItem({
    required String id,
    String? ingredientName,
    String? amount,
    bool? checked,
  }) async {
    final payload = <String, dynamic>{};
    if (ingredientName != null) {
      payload['ingredientName'] = ingredientName;
    }
    if (amount != null) {
      payload['amount'] = amount;
    }
    if (checked != null) {
      payload['checked'] = checked;
    }

    final response = await _dio.patch('/shopping-list/$id', data: payload);

    return ShoppingListItemModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteShoppingListItem(String id) async {
    await _dio.delete('/shopping-list/$id');
  }
}

final shoppingListServiceProvider = Provider<ShoppingListService>((ref) {
  return ShoppingListService(ref.read(dioProvider));
});
