import 'package:flutter/material.dart';

/// Google "G" logo — загружается из сети (официальный PNG).
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24});

  static const String _googleLogoPng =
      'https://developers.google.com/identity/images/g-logo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        _googleLogoPng,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback: простая иконка Google
          return Icon(
            Icons.g_mobiledata_rounded,
            size: size,
            color: const Color(0xFF4285F4),
          );
        },
      ),
    );
  }
}
