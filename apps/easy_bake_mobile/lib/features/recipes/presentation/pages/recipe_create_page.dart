import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/services/ai_recipe_service.dart';
import '../../data/services/recipe_service.dart';
import '../../domain/models/recipe_model.dart';
import '../providers/recipe_providers.dart';
import '../widgets/ai_prompt_section.dart';
import '../widgets/recipe_form.dart';

class RecipeCreatePage extends ConsumerStatefulWidget {
  final bool useAi;

  const RecipeCreatePage({super.key, this.useAi = false});

  @override
  ConsumerState<RecipeCreatePage> createState() => _RecipeCreatePageState();
}

class _RecipeCreatePageState extends ConsumerState<RecipeCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _healthScoreController = TextEditingController(text: '5');
  final _promptController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  Future<void> _createRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recipe = RecipeModel(
        title: _titleController.text.trim(),
        ingredients: _ingredientsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        instructions: _instructionsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        healthScore: int.tryParse(_healthScoreController.text) ?? 5,
      );

      final service = ref.read(recipeServiceProvider);
      await service.createRecipe(recipe);
      ref.invalidate(recipesListProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateFromPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = AiRecipeService();
      final generated = await aiService.generateRecipe(prompt);

      _titleController.text = generated.title;
      _ingredientsController.text = generated.ingredients.join(', ');
      _instructionsController.text = generated.instructions.join('\n');
      _healthScoreController.text = generated.healthScore.toString();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _healthScoreController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.useAi ? 'AI Recipe' : 'Create Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.useAi)
              AiPromptSection(
                promptController: _promptController,
                isLoading: _isLoading,
                onGenerate: _generateFromPrompt,
              ),
            RecipeForm(
              formKey: _formKey,
              titleController: _titleController,
              ingredientsController: _ingredientsController,
              instructionsController: _instructionsController,
              healthScoreController: _healthScoreController,
              isLoading: _isLoading,
              error: _error,
              onSave: _createRecipe,
            ),
          ],
        ),
      ),
    );
  }
}
