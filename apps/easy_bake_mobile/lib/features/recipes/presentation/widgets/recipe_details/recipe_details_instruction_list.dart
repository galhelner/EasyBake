import 'package:flutter/material.dart';

class RecipeDetailsInstructionList extends StatelessWidget {
  const RecipeDetailsInstructionList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'No instructions available.',
        style: TextStyle(color: Color(0xFF2B3D5A), fontSize: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cooking Steps',
          style: TextStyle(
            color: Color(0xFF243954),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < items.length; i++)
          _InstructionStepTile(
            stepNumber: i + 1,
            text: items[i],
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}

class _InstructionStepTile extends StatelessWidget {
  const _InstructionStepTile({
    required this.stepNumber,
    required this.text,
    required this.isLast,
  });

  final int stepNumber;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8BB3D6),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFF2B3D5A), width: 1.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Color(0xFF1F324A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: const Color(0xFFCBD7E6),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD7E6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF2B3D5A),
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
