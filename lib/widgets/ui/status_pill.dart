import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  final String status; // pending, approved, completed, declined

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    switch (s) {
      case 'approved':
        bg = cs.primary;
        fg = cs.onPrimary;
        break;
      case 'completed':
        bg = Colors.teal;
        fg = Colors.white;
        break;
      case 'declined':
        bg = Colors.red;
        fg = Colors.white;
        break;
      case 'pending':
      default:
        bg = cs.secondary;
        fg = cs.onSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
