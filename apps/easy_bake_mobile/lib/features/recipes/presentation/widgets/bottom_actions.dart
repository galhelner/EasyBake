import 'package:flutter/material.dart';

class BottomActions extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback? onAiCreate;

  const BottomActions({super.key, required this.onCreate, this.onAiCreate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: FloatingActionButton(
              heroTag: 'create',
              backgroundColor: const Color(0xFF8BB3D6),
              elevation: 0,
              onPressed: onCreate,
              child: const Icon(Icons.add, size: 38, color: Colors.white),
            ),
          ),
          SizedBox(
            width: 68,
            height: 68,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFF304466), width: 2),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAiCreate ?? () {},
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/app_logo.png',
                        width: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Positioned(
                      right: 14,
                      top: 10,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFFC857),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
