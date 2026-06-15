import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/services/shopping_list_service.dart';
import '../../domain/models/shopping_list_item_model.dart';

class ShoppingListItemsNotifier
    extends AsyncNotifier<List<ShoppingListItemModel>> {
  @override
  FutureOr<List<ShoppingListItemModel>> build() async {
    final authState = ref.watch(authNotifierProvider);

    if (!authState.isAuthenticated || authState.accessToken == null) {
      throw Exception('Not authenticated - token is invalid or expired');
    }

    final service = ref.read(shoppingListServiceProvider);
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);

    try {
      final rawItems = await service
          .fetchShoppingList(cancelToken: cancelToken)
          .timeout(const Duration(seconds: 45));

      final prefs = await SharedPreferences.getInstance();
      final userId = authState.userId ?? 'anonymous';
      final orderKeys = prefs.getStringList('shopping_list_order_$userId') ?? [];

      return _sortItems(rawItems, orderKeys, userId);
    } on TimeoutException {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Timed out while loading shopping list');
      }
      throw Exception(
        'Server is not responding. Please check if recipe-service is running and try again.',
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw Exception('Request cancelled');
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot reach the server. Please start recipe-service and refresh.',
        );
      }

      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(authNotifierProvider.notifier).clear();
        });
        throw Exception('Your session has expired. Please sign in again.');
      }
      if (statusCode == 404) {
        throw Exception('Shopping list not found.');
      }
      if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
        throw Exception('Server error. Please try again later.');
      }
      if (statusCode != null) {
        throw Exception(
          'An error occurred while loading the shopping list. Please try again.',
        );
      }
      rethrow;
    }
  }

  List<ShoppingListItemModel> _sortItems(
    List<ShoppingListItemModel> items,
    List<String> orderKeys,
    String userId,
  ) {
    if (orderKeys.isEmpty) {
      return items;
    }

    final itemMap = {for (final item in items) item.id: item};
    final sortedList = <ShoppingListItemModel>[];

    for (final id in orderKeys) {
      final item = itemMap.remove(id);
      if (item != null) {
        sortedList.add(item);
      }
    }

    if (itemMap.isNotEmpty) {
      sortedList.insertAll(0, itemMap.values);
      unawaited(_saveOrder(sortedList.map((e) => e.id).toList(), userId));
    }

    return sortedList;
  }

  Future<void> _saveOrder(List<String> orderKeys, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shopping_list_order_$userId', orderKeys);
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    final items = state.value;
    if (items == null) return;

    final updatedItems = List<ShoppingListItemModel>.from(items);
    final item = updatedItems.removeAt(oldIndex);
    updatedItems.insert(newIndex, item);

    state = AsyncData(updatedItems);

    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId ?? 'anonymous';
    await _saveOrder(updatedItems.map((e) => e.id).toList(), userId);
  }
}

final shoppingListItemsProvider = AsyncNotifierProvider.autoDispose<
    ShoppingListItemsNotifier, List<ShoppingListItemModel>>(
  ShoppingListItemsNotifier.new,
);

class ShoppingListOptimisticCheckedNotifier
    extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void updateState(Map<String, bool> Function(Map<String, bool>) update) {
    state = update(state);
  }

  void setState(Map<String, bool> newState) {
    state = newState;
  }
}

final shoppingListOptimisticCheckedProvider = NotifierProvider<
    ShoppingListOptimisticCheckedNotifier, Map<String, bool>>(
  ShoppingListOptimisticCheckedNotifier.new,
);
