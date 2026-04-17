import 'package:flutter/material.dart';

class Icon3D extends StatelessWidget {
  final String emoji;
  final double size;

  const Icon3D({super.key, required this.emoji, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    String? assetPath;
    IconData? fallbackIcon;
    Color? fallbackColor;

    switch (emoji) {
      case '🎯':
        assetPath = 'assets/icons/3d/target.png';
        break;
      case '📈':
        assetPath = 'assets/icons/3d/chart.png';
        break;
      case '📚':
        assetPath = 'assets/icons/3d/books.png';
        break;
      case '✨':
        assetPath = 'assets/icons/3d/sparkles.png';
        break;
      case '👔':
        assetPath = 'assets/icons/3d/briefcase.png';
        break;
      case '🏢':
        assetPath = 'assets/icons/3d/building.png';
        break;
      case '💡':
        assetPath = 'assets/icons/3d/sparkles.png'; // Will use sparkles for ideas as well
        break;
      case '⬆️':
        fallbackIcon = Icons.arrow_upward_rounded;
        fallbackColor = Colors.green;
        break;
      case '⬇️':
        fallbackIcon = Icons.arrow_downward_rounded;
        fallbackColor = Colors.red;
        break;
      case '➡️':
        fallbackIcon = Icons.arrow_forward_rounded;
        fallbackColor = Colors.grey;
        break;
      default:
        // Return normal text if no 3d icon available
        return Text(emoji, style: TextStyle(fontSize: size * 0.8));
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (fallbackIcon != null) {
      return Icon(
        fallbackIcon,
        size: size * 0.9,
        color: fallbackColor,
      );
    }

    return Text(emoji, style: TextStyle(fontSize: size * 0.8));
  }
}
