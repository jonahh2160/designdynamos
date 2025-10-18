import 'package:flutter/material.dart';

class Dot extends StatelessWidget {
  final Color? color;
  final double size;

  const Dot({
    super.key,
    this.color,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
