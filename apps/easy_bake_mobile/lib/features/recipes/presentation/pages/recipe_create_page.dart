import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

import '../../data/services/recipe_service.dart';
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
  final List<TextEditingController> _instructionControllers = [
    TextEditingController(),
  ];
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  XFile? _selectedImageFile;
  String? _titleError;
  String? _ingredientError;

  @override
  void initState() {
    super.initState();
    _applyInitialRecipe();
  }

  void _applyInitialRecipe() {
    final initialRecipe = widget.initialRecipe ??
        (widget.initialRecipeJson != null
            ? RecipeModel.fromJson(widget.initialRecipeJson!)
            : null);

    if (initialRecipe == null) {
      return;
    }

    _titleController.text = initialRecipe.title;
    _replaceControllerValues(_ingredientControllers, initialRecipe.ingredients);
    _replaceControllerValues(_instructionControllers, initialRecipe.instructions);
  }

  void _replaceControllerValues(
    List<TextEditingController> target,
    List<String> values,
  ) {
    for (final controller in target) {
      controller.dispose();
    }
    target.clear();

    final normalized = values
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
  }

  Future<void> _createRecipe() async {
    if (!_validateRequiredFields()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ingredients = _collectValues(_ingredientControllers);
      final instructions = _collectValues(_instructionControllers);

      final recipe = RecipeModel(
        title: _titleController.text.trim(),
        ingredients: ingredients,
        instructions: instructions,
        healthScore: 5,
      );

      final service = ref.read(recipeServiceProvider);
      await service.createRecipeWithOptionalImage(
        recipe,
        imageFilePath: _selectedImageFile?.path,
      );
      ref.invalidate(recipesListProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
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

  void _handleIngredientChanged(String _) {
    if (_ingredientError == null) return;
    if (_collectValues(_ingredientControllers).isEmpty) return;
    setState(() {
      _ingredientError = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _ingredientControllers) {
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

  void _addIngredientField() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredientField(int index) {
    if (_ingredientControllers.length <= 1) return;
    setState(() {
      final removed = _ingredientControllers.removeAt(index);
      removed.dispose();
    });
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
      });
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
        'We could not open your camera or gallery. Please try again.',
      );
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400) {
        final serverMessage = error.response?.data is Map
            ? (error.response?.data['message'] as String?)
            : null;
        return serverMessage ??
            'Some recipe details are invalid. Please review your inputs and try again.';
      }
      if (statusCode == 401 || statusCode == 403) {
        return 'Your session has expired. Please sign in again.';
      }
      if (statusCode == 409) {
        return 'This recipe already exists. Try a different title.';
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
        child: SingleChildScrollView(
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
                ),
                const SizedBox(height: 28),
                RecipeCreateUploadCard(
                  primaryColor: _kButtonBlue,
                  backgroundColor: _kUploadCardBackground,
                  imageBytes: _selectedImageBytes,
                  onTap: _showImageSourceOptions,
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
                RecipeCreateDynamicSection(
                  title: 'Ingredients',
                  fieldHint: 'Ingredient',
                  controllers: _ingredientControllers,
                  onAdd: _addIngredientField,
                  onRemove: _removeIngredientField,
                  primaryColor: _kPrimaryBlue,
                  hintColor: _kHintText,
                  minLines: 1,
                  maxLines: 3,
                  hasError: _ingredientError != null,
                  errorText: _ingredientError,
                  onFieldChanged: _handleIngredientChanged,
                ),
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
                    onPressed: _isLoading ? null : _createRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kButtonBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor:
                          _kButtonBlue.withValues(alpha: 0.5),
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
      ),
    );
  }
}
