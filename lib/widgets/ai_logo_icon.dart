import 'package:flutter/material.dart';

class AILogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AILogoIcon({super.key, this.size = 24.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.psychology_outlined,
      size: size,
      color: color ?? Theme.of(context).primaryColor,
    );
  }
}
