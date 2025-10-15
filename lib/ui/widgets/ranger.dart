import 'package:flutter/material.dart';

class Ranger extends StatelessWidget {
  final String from;
  final String to;

  const Ranger({
    super.key,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 18),
        const SizedBox(width: 8),
        Text(
          "$from - $to",
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
