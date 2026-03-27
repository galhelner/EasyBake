import 'package:flutter/material.dart';

class RecipeForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController ingredientsController;
  final TextEditingController instructionsController;
  final TextEditingController healthScoreController;
  final bool isLoading;
  final String? error;
  final VoidCallback onSave;

  const RecipeForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.ingredientsController,
    required this.instructionsController,
    required this.healthScoreController,
    required this.isLoading,
    required this.error,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: titleController,
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
            controller: ingredientsController,
            decoration: const InputDecoration(
              labelText: 'Ingredients',
              hintText: 'Comma-separated list of ingredients',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: instructionsController,
            decoration: const InputDecoration(
              labelText: 'Instructions',
              hintText: 'One instruction per line',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: healthScoreController,
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
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isLoading ? null : onSave,
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save recipe'),
          ),
        ],
      ),
    );
  }
}
