import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

import '../../data/services/recipe_service.dart';
import '../../domain/models/ingredient_suggestion_model.dart';
import '../../domain/models/recipe_model.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_create/recipe_create_dynamic_section.dart';
import '../widgets/recipe_create/recipe_create_header.dart';
import '../widgets/recipe_create/recipe_create_input_field.dart';
import '../widgets/recipe_create/recipe_create_upload_card.dart';

class RecipeCreatePage extends ConsumerStatefulWidget {
  const RecipeCreatePage({
    super.key,
    this.initialRecipe,
    this.initialRecipeJson,
  });

  final RecipeModel? initialRecipe;
  final Map<String, dynamic>? initialRecipeJson;

  @override
  ConsumerState<RecipeCreatePage> createState() => _RecipeCreatePageState();
}

class _RecipeCreatePageState extends ConsumerState<RecipeCreatePage> {
  static const _kPageBackground = Color(0xFFF5F7FA);
  static const _kPrimaryBlue = Color(0xFF2E4E69);
  static const _kButtonBlue = Color(0xFF8BB3D6);
  static const _kHintText = Color(0xFF4E677D);
  static const _kUploadCardBackground = Color(0xFFF0F4F7);
  static const _kLogoAssetPath = 'assets/app_logo.png';

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();

  final List<TextEditingController> _ingredientControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _ingredientAmountControllers = [
    TextEditingController(),
  ];
  final List<List<IngredientSuggestionModel>> _ingredientSuggestions = [
    const <IngredientSuggestionModel>[],
  ];
  final List<String> _ingredientSelectedIcons = [''];
  final List<bool> _isIngredientSearchLoading = [false];
  final List<Timer?> _ingredientSearchDebouncers = [null];
  final List<bool> _isApplyingIngredientSuggestion = [false];
  final List<TextEditingController> _instructionControllers = [
    TextEditingController(),
  ];
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  XFile? _selectedImageFile;
  String? _existingImageUrl;
  bool _removeExistingImage = false;
  String? _titleError;
  String? _ingredientError;

  bool get _isEditMode {
    final initialRecipe =
        widget.initialRecipe ??
        (widget.initialRecipeJson != null
            ? RecipeModel.fromJson(widget.initialRecipeJson!)
            : null);

    final id = initialRecipe?.id;
    return id != null && id.isNotEmpty;
  }

  RecipeModel? get _resolvedInitialRecipe {
    return widget.initialRecipe ??
        (widget.initialRecipeJson != null
            ? RecipeModel.fromJson(widget.initialRecipeJson!)
            : null);
  }

  @override
  void initState() {
    super.initState();
    _applyInitialRecipe();
  }

  void _applyInitialRecipe() {
    final initialRecipe = _resolvedInitialRecipe;

    if (initialRecipe == null) {
      return;
    }

    _titleController.text = initialRecipe.title;
    _replaceControllerValues(_ingredientControllers, initialRecipe.ingredients);
    _replaceControllerValues(
      _ingredientAmountControllers,
      _mapAmountsToIngredientOrder(initialRecipe),
      preserveEmptyEntries: true,
    );
    _replaceControllerValues(
      _instructionControllers,
      initialRecipe.instructions,
    );
    _applyInitialIngredientIcons(initialRecipe);
    _existingImageUrl = _hasCustomImageUrl(initialRecipe.imageUrl)
        ? initialRecipe.imageUrl
        : null;
    _removeExistingImage = false;
  }

  bool _hasCustomImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }
    return !url.toLowerCase().contains('default-recipe.jpg');
  }

  void _applyInitialIngredientIcons(RecipeModel initialRecipe) {
    if (_ingredientControllers.isEmpty || initialRecipe.ingredientIcons.isEmpty) {
      return;
    }

    final normalizedIconByName = <String, String>{
      for (final entry in initialRecipe.ingredientIcons.entries)
        entry.key.trim().toLowerCase(): entry.value,
    };

    for (var i = 0; i < _ingredientControllers.length; i++) {
      final ingredientName = _ingredientControllers[i].text.trim().toLowerCase();
      _ingredientSelectedIcons[i] = normalizedIconByName[ingredientName] ?? '';
    }
  }

  List<String> _mapAmountsToIngredientOrder(RecipeModel recipe) {
    final normalizedAmountByName = <String, String>{
      for (final entry in recipe.ingredientAmounts.entries)
        entry.key.trim().toLowerCase(): entry.value,
    };

    return recipe.ingredients
        .map(
          (name) => normalizedAmountByName[name.trim().toLowerCase()] ?? '',
        )
        .toList();
  }

  void _replaceControllerValues(
    List<TextEditingController> target,
    List<String> values,
    {bool preserveEmptyEntries = false}
  ) {
    if (identical(target, _ingredientControllers)) {
      for (final timer in _ingredientSearchDebouncers) {
        timer?.cancel();
      }
      _ingredientSuggestions
        ..clear()
        ..add(const <IngredientSuggestionModel>[]);
      _ingredientSelectedIcons
        ..clear()
        ..add('');
      _isIngredientSearchLoading
        ..clear()
        ..add(false);
      _ingredientSearchDebouncers
        ..clear()
        ..add(null);
      _isApplyingIngredientSuggestion
        ..clear()
        ..add(false);
    }

    for (final controller in target) {
      controller.dispose();
    }
    target.clear();

    final normalized = preserveEmptyEntries
      ? values.map((value) => value.trim()).toList()
      : values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

    if (normalized.isEmpty) {
      target.add(TextEditingController());
      return;
    }

    target.addAll(
      normalized.map((value) => TextEditingController(text: value)),
    );

    if (identical(target, _ingredientControllers)) {
      _ingredientSuggestions
        ..clear()
        ..addAll(
          List.generate(
            target.length,
            (_) => const <IngredientSuggestionModel>[],
          ),
        );
      _ingredientSelectedIcons
        ..clear()
        ..addAll(List.generate(target.length, (_) => ''));
      _isIngredientSearchLoading
        ..clear()
        ..addAll(List.generate(target.length, (_) => false));
      _ingredientSearchDebouncers
        ..clear()
        ..addAll(List.generate(target.length, (_) => null));
      _isApplyingIngredientSuggestion
        ..clear()
        ..addAll(List.generate(target.length, (_) => false));
    }
  }

  Future<void> _saveRecipe() async {
    if (!_validateRequiredFields()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ingredients = _collectValues(_ingredientControllers);
      final ingredientAmounts = _collectIngredientAmountsByName();
      final instructions = _collectValues(_instructionControllers);

      final recipe = RecipeModel(
        title: _titleController.text.trim(),
        ingredients: ingredients,
        ingredientAmounts: ingredientAmounts,
        instructions: instructions,
        healthScore: 5,
      );

      final service = ref.read(recipeServiceProvider);
      final existingId = _resolvedInitialRecipe?.id;
      final savedRecipe =
          _isEditMode && existingId != null && existingId.isNotEmpty
          ? await service.updateRecipeWithOptionalImage(
              existingId,
              recipe,
              imageFilePath: _selectedImageFile?.path,
              removeExistingImage: _removeExistingImage,
            )
          : await service.createRecipeWithOptionalImage(
              recipe,
              imageFilePath: _selectedImageFile?.path,
            );
      ref.invalidate(recipesListProvider);

      if (mounted) {
        Navigator.of(context).pop(savedRecipe);
      }
    } catch (e) {
      final ingredients = _collectValues(_ingredientControllers);
      final ingredientAmounts = _collectIngredientAmountsByName();
      final instructions = _collectValues(_instructionControllers);

      final attemptedRecipe = RecipeModel(
        title: _titleController.text.trim(),
        ingredients: ingredients,
        ingredientAmounts: ingredientAmounts,
        instructions: instructions,
        healthScore: 5,
      );

      final existingId = _resolvedInitialRecipe?.id;
      final recovered = await _tryRecoverTimedOutSave(
        error: e,
        attemptedRecipe: attemptedRecipe,
        existingId: existingId,
      );

      if (recovered != null) {
        ref.invalidate(recipesListProvider);
        if (mounted) {
          Navigator.of(context).pop(recovered);
        }
        return;
      }

      if (mounted) {
        await _showErrorDialog(_friendlyErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<RecipeModel?> _tryRecoverTimedOutSave({
    required Object error,
    required RecipeModel attemptedRecipe,
    required String? existingId,
  }) async {
    if (error is! DioException) {
      return null;
    }

    if (!_shouldAttemptSaveRecovery(error)) {
      return null;
    }

    final service = ref.read(recipeServiceProvider);

    try {
      // Azure free-tier cold starts can finish slightly after client timeout.
      for (var attempt = 0; attempt < 3; attempt++) {
        if (_isEditMode && existingId != null && existingId.isNotEmpty) {
          final refreshed = await service.fetchRecipeById(existingId);
          if (_looksLikeSameRecipe(refreshed, attemptedRecipe)) {
            return refreshed;
          }
        } else {
          final recipes = await service.fetchRecipes();
          for (final candidate in recipes.reversed) {
            if (_looksLikeSameRecipe(candidate, attemptedRecipe)) {
              return candidate;
            }
          }
        }

        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _shouldAttemptSaveRecovery(DioException error) {
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionTimeout) {
      return true;
    }

    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      return statusCode == 408 ||
          statusCode == 499 ||
          statusCode == 500 ||
          statusCode == 502 ||
          statusCode == 503 ||
          statusCode == 504;
    }

    return false;
  }

  bool _looksLikeSameRecipe(RecipeModel a, RecipeModel b) {
    if (a.title.trim().toLowerCase() != b.title.trim().toLowerCase()) {
      return false;
    }

    final ingredientsA = a.ingredients
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    final ingredientsB = b.ingredients
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();

    if (ingredientsA.length != ingredientsB.length ||
        !ingredientsA.containsAll(ingredientsB)) {
      return false;
    }

    final instructionsA = a.instructions
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();
    final instructionsB = b.instructions
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();

    if (instructionsA.length != instructionsB.length) {
      return false;
    }

    for (var i = 0; i < instructionsA.length; i++) {
      if (instructionsA[i] != instructionsB[i]) {
        return false;
      }
    }

    return true;
  }

  bool _validateRequiredFields() {
    final titleMissing = _titleController.text.trim().isEmpty;
    final ingredientsMissing = _collectValues(_ingredientControllers).isEmpty;

    setState(() {
      _titleError = titleMissing ? 'Recipe title is required.' : null;
      _ingredientError = ingredientsMissing
          ? 'At least one ingredient is required.'
          : null;
    });

    return !titleMissing && !ingredientsMissing;
  }

  void _handleTitleChanged(String value) {
    if (_titleError == null) return;
    if (value.trim().isEmpty) return;
    setState(() {
      _titleError = null;
    });
  }

  void _handleIngredientChanged(String _, {int? index}) {
    if (index != null && index < _isApplyingIngredientSuggestion.length) {
      if (_isApplyingIngredientSuggestion[index]) {
        return;
      }
    }

    final hasAnyIngredient = _collectValues(_ingredientControllers).isNotEmpty;

    if (_ingredientError != null && hasAnyIngredient) {
      setState(() {
        _ingredientError = null;
      });
    }

    if (index != null && index < _ingredientSelectedIcons.length) {
      if (_ingredientSelectedIcons[index].isNotEmpty) {
        setState(() {
          _ingredientSelectedIcons[index] = '';
        });
      }
    }

    if (index != null) {
      _scheduleIngredientSearch(index);
    }
  }

  Future<void> _scheduleIngredientSearch(int index) async {
    if (index >= _ingredientControllers.length) {
      return;
    }

    _ingredientSearchDebouncers[index]?.cancel();

    final query = _ingredientControllers[index].text.trim();
    if (query.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ingredientSuggestions[index] = const <IngredientSuggestionModel>[];
        _isIngredientSearchLoading[index] = false;
      });
      return;
    }

    setState(() {
      _isIngredientSearchLoading[index] = true;
    });

    _ingredientSearchDebouncers[index] = Timer(
      const Duration(milliseconds: 250),
      () async {
        try {
          final service = ref.read(recipeServiceProvider);
          final matches = await service.fetchIngredientSuggestions(query);
          if (!mounted || index >= _ingredientControllers.length) {
            return;
          }

          final latestText = _ingredientControllers[index].text.trim();
          if (latestText != query) {
            return;
          }

          setState(() {
            _ingredientSuggestions[index] = matches;
            _isIngredientSearchLoading[index] = false;
          });
        } catch (_) {
          if (!mounted || index >= _ingredientControllers.length) {
            return;
          }

          setState(() {
            _ingredientSuggestions[index] = const <IngredientSuggestionModel>[];
            _isIngredientSearchLoading[index] = false;
          });
        }
      },
    );
  }

  void _selectIngredientSuggestion(
    int index,
    IngredientSuggestionModel suggestion,
  ) {
    if (index >= _ingredientControllers.length) {
      return;
    }

    final controller = _ingredientControllers[index];
    _isApplyingIngredientSuggestion[index] = true;
    controller.text = suggestion.name;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    setState(() {
      _ingredientSuggestions[index] = const <IngredientSuggestionModel>[];
      _ingredientSelectedIcons[index] = suggestion.icon;
      _isIngredientSearchLoading[index] = false;
      if (_ingredientError != null &&
          _collectValues(_ingredientControllers).isNotEmpty) {
        _ingredientError = null;
      }
    });

    Future.microtask(() {
      if (!mounted || index >= _isApplyingIngredientSuggestion.length) {
        return;
      }
      _isApplyingIngredientSuggestion[index] = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final timer in _ingredientSearchDebouncers) {
      timer?.cancel();
    }
    for (final suggestion in _ingredientSelectedIcons) {
      suggestion;
    }
    for (final controller in _ingredientControllers) {
      controller.dispose();
    }
    for (final controller in _ingredientAmountControllers) {
      controller.dispose();
    }
    for (final controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> _collectValues(List<TextEditingController> controllers) {
    return controllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Map<String, String> _collectIngredientAmountsByName() {
    final result = <String, String>{};
    final rowCount = _ingredientControllers.length < _ingredientAmountControllers.length
        ? _ingredientControllers.length
        : _ingredientAmountControllers.length;

    for (var i = 0; i < rowCount; i++) {
      final name = _ingredientControllers[i].text.trim();
      if (name.isEmpty) {
        continue;
      }

      final amount = _ingredientAmountControllers[i].text.trim();
      if (amount.isEmpty) {
        continue;
      }

      result[name] = amount;
    }

    return result;
  }

  void _addIngredientField() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
      _ingredientAmountControllers.add(TextEditingController());
      _ingredientSuggestions.add(const <IngredientSuggestionModel>[]);
      _ingredientSelectedIcons.add('');
      _isIngredientSearchLoading.add(false);
      _ingredientSearchDebouncers.add(null);
      _isApplyingIngredientSuggestion.add(false);
    });
  }

  void _removeIngredientField(int index) {
    if (_ingredientControllers.length <= 1) return;
    setState(() {
      _ingredientSearchDebouncers[index]?.cancel();
      final removed = _ingredientControllers.removeAt(index);
      removed.dispose();
      final removedAmount = _ingredientAmountControllers.removeAt(index);
      removedAmount.dispose();
      _ingredientSuggestions.removeAt(index);
      _ingredientSelectedIcons.removeAt(index);
      _isIngredientSearchLoading.removeAt(index);
      _ingredientSearchDebouncers.removeAt(index);
      _isApplyingIngredientSuggestion.removeAt(index);
    });
  }

  Widget _buildIngredientSuggestions(int index) {
    final suggestions = _ingredientSuggestions[index];
    final isLoading = _isIngredientSearchLoading[index];

    if (!isLoading && suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E8ED)),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Searching ingredients...',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, suggestionIndex) {
                  final suggestion = suggestions[suggestionIndex];
                  return ListTile(
                    dense: true,
                    leading: suggestion.icon.isEmpty
                        ? null
                        : Text(
                            suggestion.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                    title: Text(suggestion.name),
                    onTap: () => _selectIngredientSuggestion(index, suggestion),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildIngredientsSection() {
    final isCompactLayout = MediaQuery.of(context).size.width < 420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Ingredients',
            style: TextStyle(
              color: _kPrimaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        for (var i = 0; i < _ingredientControllers.length; i++) ...[
          if (isCompactLayout)
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RecipeCreateInputField(
                        controller: _ingredientControllers[i],
                        hintText: 'Ingredient #${i + 1}',
                        primaryColor: _kPrimaryBlue,
                        hintColor: _kHintText,
                        hasError: _ingredientError != null,
                        prefixIcon: _ingredientSelectedIcons[i].isEmpty
                            ? null
                            : Text(
                                _ingredientSelectedIcons[i],
                                style: const TextStyle(fontSize: 18),
                              ),
                        minLines: 1,
                        maxLines: 1,
                        onChanged: (value) =>
                            _handleIngredientChanged(value, index: i),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: _buildFieldActionButton(
                        onTap: _addIngredientField,
                        icon: Icons.add_rounded,
                        isRemove: false,
                      ),
                    ),
                    if (_ingredientControllers.length > 1) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: _buildFieldActionButton(
                          onTap: () => _removeIngredientField(i),
                          icon: Icons.remove_rounded,
                          isRemove: true,
                        ),
                      ),
                    ],
                  ],
                ),
                _buildIngredientSuggestions(i),
                const SizedBox(height: 8),
                RecipeCreateInputField(
                  controller: _ingredientAmountControllers[i],
                  hintText: 'Amount (e.g. 200 g, 120 ml, 2)',
                  primaryColor: _kPrimaryBlue,
                  hintColor: _kHintText,
                  minLines: 1,
                  maxLines: 1,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      RecipeCreateInputField(
                        controller: _ingredientControllers[i],
                        hintText: 'Ingredient #${i + 1}',
                        primaryColor: _kPrimaryBlue,
                        hintColor: _kHintText,
                        hasError: _ingredientError != null,
                        prefixIcon: _ingredientSelectedIcons[i].isEmpty
                            ? null
                            : Text(
                                _ingredientSelectedIcons[i],
                                style: const TextStyle(fontSize: 18),
                              ),
                        minLines: 1,
                        maxLines: 1,
                        onChanged: (value) =>
                            _handleIngredientChanged(value, index: i),
                      ),
                      _buildIngredientSuggestions(i),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: RecipeCreateInputField(
                    controller: _ingredientAmountControllers[i],
                    hintText: 'Amount',
                    primaryColor: _kPrimaryBlue,
                    hintColor: _kHintText,
                    minLines: 1,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: _buildFieldActionButton(
                    onTap: _addIngredientField,
                    icon: Icons.add_rounded,
                    isRemove: false,
                  ),
                ),
                if (_ingredientControllers.length > 1) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: _buildFieldActionButton(
                      onTap: () => _removeIngredientField(i),
                      icon: Icons.remove_rounded,
                      isRemove: true,
                    ),
                  ),
                ],
              ],
            ),
          if (i < _ingredientControllers.length - 1) const SizedBox(height: 10),
        ],
        if (_ingredientError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _ingredientError!,
              style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required bool isRemove,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 48,
          decoration: BoxDecoration(
            color: isRemove
                ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                : const Color(0xFF8BB3D6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isRemove
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.2)
                  : const Color(0xFF8BB3D6).withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isRemove
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF8BB3D6),
            ),
          ),
        ),
      ),
    );
  }

  void _addInstructionField() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstructionField(int index) {
    if (_instructionControllers.length <= 1) return;
    setState(() {
      final removed = _instructionControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _showImageSourceOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Picture'),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    await _pickRecipeImage(source);
  }

  Future<void> _pickRecipeImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageFile = picked;
        _selectedImageBytes = bytes;
        _removeExistingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
        'We could not open your camera or gallery. Please try again.',
      );
    }
  }

  void _removeRecipeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
      if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        _removeExistingImage = true;
      }
      _existingImageUrl = null;
    });
  }

  String _friendlyErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final serverData = error.response?.data;

      String? extractServerMessage() {
        if (serverData is! Map) {
          return null;
        }

        final message = serverData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }

        final errorText = serverData['error']?.toString().trim();
        if (errorText != null && errorText.isNotEmpty) {
          return errorText;
        }

        final details = serverData['details'];
        if (details is Map) {
          final fieldErrors = details['fieldErrors'];
          if (fieldErrors is Map) {
            for (final value in fieldErrors.values) {
              if (value is List && value.isNotEmpty) {
                final first = value.first?.toString().trim();
                if (first != null && first.isNotEmpty) {
                  return first;
                }
              }
            }
          }

          final formErrors = details['formErrors'];
          if (formErrors is List && formErrors.isNotEmpty) {
            final first = formErrors.first?.toString().trim();
            if (first != null && first.isNotEmpty) {
              return first;
            }
          }
        }

        return null;
      }

      final serverMessage = extractServerMessage();

      if (statusCode == 400) {
        return serverMessage ??
            'Some recipe details are invalid. Please review your inputs and try again.';
      }
      if (statusCode == 401 || statusCode == 403) {
        return serverMessage ?? 'Your session has expired. Please sign in again.';
      }
      if (statusCode == 409) {
        return serverMessage ?? 'This recipe already exists. Try a different title.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'The server is having trouble right now. Please try again in a moment.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'We could not reach the server. Check your internet connection and try again.';
      }

      if (serverMessage != null && serverMessage.isNotEmpty) {
        return serverMessage;
      }

      if (error.type == DioExceptionType.badResponse) {
        return 'The server is taking longer than expected. Please check your recipes list in a moment.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Something Went Wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RecipeCreateHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      primaryColor: _kPrimaryBlue,
                      logoAssetPath: _kLogoAssetPath,
                      isEditMode: _isEditMode,
                    ),
                    const SizedBox(height: 28),
                    RecipeCreateUploadCard(
                      primaryColor: _kButtonBlue,
                      backgroundColor: _kUploadCardBackground,
                      imageBytes: _selectedImageBytes,
                      imageUrl: _selectedImageBytes == null
                          ? _existingImageUrl
                          : null,
                      onReplace: _showImageSourceOptions,
                      onDelete: (_selectedImageBytes != null ||
                              (_existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty))
                          ? _removeRecipeImage
                          : null,
                    ),
                    const SizedBox(height: 28),
                    RecipeCreateInputField(
                      controller: _titleController,
                      hintText: 'Recipe Title',
                      primaryColor: _kPrimaryBlue,
                      hintColor: _kHintText,
                      hasError: _titleError != null,
                      onChanged: _handleTitleChanged,
                    ),
                    if (_titleError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _titleError!,
                          style: const TextStyle(
                            color: Color(0xFFFF3B30),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _buildIngredientsSection(),
                    const SizedBox(height: 28),
                    RecipeCreateDynamicSection(
                      title: 'Instructions',
                      fieldHint: 'Instruction Step',
                      controllers: _instructionControllers,
                      onAdd: _addInstructionField,
                      onRemove: _removeInstructionField,
                      primaryColor: _kPrimaryBlue,
                      hintColor: _kHintText,
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kButtonBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: _kButtonBlue.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Recipe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.24),
                  child: Center(
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            _kLogoAssetPath,
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isEditMode
                                ? 'Saving your changes...'
                                : 'Creating your recipe...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF2E4E69),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(
                              minHeight: 7,
                              backgroundColor: Color(0xFFD7E6F1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _kPrimaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
