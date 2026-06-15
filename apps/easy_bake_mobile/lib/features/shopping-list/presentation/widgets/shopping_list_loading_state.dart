import 'package:flutter/material.dart';

class ShoppingListLoadingState extends StatelessWidget {
  const ShoppingListLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF17324B))),
    );
  }
}
