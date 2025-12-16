import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RatingBadge extends StatelessWidget {
  final String tutorId;
  final double? fallbackAvg;
  final int? fallbackCount;
  const RatingBadge({
    super.key,
    required this.tutorId,
    this.fallbackAvg,
    this.fallbackCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(tutorId).snapshots(),
      builder: (context, snapshot) {
        double avg = fallbackAvg ?? 0;
        int count = fallbackCount ?? 0;
        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          final a = data['ratingAvg'];
          final c = data['ratingCount'];
          if (a is num) avg = a.toDouble();
          if (c is num) count = c.toInt();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text(
              avg.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text('($count)', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ],
        );
      },
    );
  }
}

