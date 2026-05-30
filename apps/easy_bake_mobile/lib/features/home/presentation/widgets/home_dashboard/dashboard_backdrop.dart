import 'package:flutter/material.dart';

class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3F7FB), Color(0xFFEAF2FB), Color(0xFFFDF8EF)],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
      ),
    );
  }
}