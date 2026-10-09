import 'package:flutter/material.dart';
import 'package:moneytrail/models/category.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 42});

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget inner;
    if (category.asset != null) {
      inner = Image.asset(
        category.asset!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.category, color: category.color, size: size * 0.5),
      );
    } else {
      inner = Icon(category.icon ?? Icons.category, color: category.color, size: size * 0.5);
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: category.color.withAlpha(36),
      ),
      child: inner,
    );
  }
}
