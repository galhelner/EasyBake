import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../auth/login_page.dart';
import 'ai_recipe_service.dart';
import 'domain/recipe_model.dart';
import 'recipe_service.dart';

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
            if (widget.useAi) ...[
              TextFormField(
                controller: _promptController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Describe what you want',
                  hintText: 'e.g. "Give me a healthy vegan pasta recipe"',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateFromPrompt,
                child: const Text('Generate recipe'),
              ),
              const Divider(height: 32),
            ],
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients',
                      hintText: 'Comma-separated list of ingredients',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                      hintText: 'One instruction per line',
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _healthScoreController,
                    decoration: const InputDecoration(
                      labelText: 'Health score',
                      hintText: '0-100',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null) {
                        return 'Enter a number';
                      }
                      if (parsed < 0 || parsed > 100) {
                        return 'Must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createRecipe,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save recipe'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
