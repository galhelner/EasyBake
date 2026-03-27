import 'package:flutter/material.dart';

class AiPromptSection extends StatelessWidget {
  final TextEditingController promptController;
  final bool isLoading;
  final VoidCallback onGenerate;

  const AiPromptSection({
    super.key,
    required this.promptController,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: promptController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Describe what you want',
            hintText: 'e.g. "Give me a healthy vegan pasta recipe"',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: isLoading ? null : onGenerate,
          child: const Text('Generate recipe'),
        ),
        const Divider(height: 32),
      ],
    );
  }
}
