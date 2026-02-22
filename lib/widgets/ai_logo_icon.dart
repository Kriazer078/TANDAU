import 'package:flutter/material.dart';

class AILogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AILogoIcon({super.key, this.size = 24.0, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: Container(
        width: size,
        height: size,
        color: Colors.white, // Forces clean white background for the logo
        child: Padding(
          padding: EdgeInsets.all(
            size * 0.1,
          ), // Built-in padding for breathing room
          child: Image.asset('assets/images/icon.jpg', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
