import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

import '../../data/services/recipe_service.dart';
import '../../domain/models/recipe_model.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_create_dynamic_section.dart';
import '../widgets/recipe_create_header.dart';
import '../widgets/recipe_create_input_field.dart';
import '../widgets/recipe_create_upload_card.dart';

class RecipeCreatePage extends ConsumerStatefulWidget {
  const RecipeCreatePage({super.key});

  @override
  ConsumerState<RecipeCreatePage> createState() => _RecipeCreatePageState();
}

class _RecipeCreatePageState extends ConsumerState<RecipeCreatePage> {
  static const _kPageBackground = Color(0xFFF2F7F7);
  static const _kPrimaryBlue = Color(0xFF2B3D5A);
  static const _kHintText = Color(0xFF706C6C);
  static const _kButtonBlue = Color(0xFF8BB3D6);
  static const _kUploadCardBackground = Color(0xFFDEECF5);
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
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
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
                const SizedBox(height: 24),
                RecipeCreateUploadCard(
                  primaryColor: _kPrimaryBlue,
                  backgroundColor: _kUploadCardBackground,
                  imageBytes: _selectedImageBytes,
                  onTap: _showImageSourceOptions,
                ),
                const SizedBox(height: 38),
                RecipeCreateInputField(
                  controller: _titleController,
                  hintText: 'Recipe Title',
                  primaryColor: _kPrimaryBlue,
                  hintColor: _kHintText,
                  hasError: _titleError != null,
                  onChanged: _handleTitleChanged,
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _titleError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
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
                  hasError: _ingredientError != null,
                  errorText: _ingredientError,
                  onFieldChanged: _handleIngredientChanged,
                ),
                const SizedBox(height: 24),
                RecipeCreateDynamicSection(
                  title: 'Instructions',
                  fieldHint: 'Instruction Step',
                  controllers: _instructionControllers,
                  onAdd: _addInstructionField,
                  onRemove: _removeInstructionField,
                  primaryColor: _kPrimaryBlue,
                  hintColor: _kHintText,
                ),
                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: 203,
                    height: 43,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createRecipe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kButtonBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Recipe',
                              style: TextStyle(
                                fontSize: 20,
                                height: 1,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
