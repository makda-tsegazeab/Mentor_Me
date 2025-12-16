import 'package:flutter/material.dart';
import '../models/tutor.dart';

class TutorCard extends StatelessWidget {
  final Tutor tutor;
  final bool isLoggedIn;
  final VoidCallback onContact;

  TutorCard({
    required this.tutor,
    required this.isLoggedIn,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(tutor.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subjects: ${tutor.subjects.join(', ')}'),
            Text('City: ${tutor.city}'),
            Text('Rate: \$${tutor.rate}/hr'),
          ],
        ),
        trailing: ElevatedButton(onPressed: onContact, child: Text('Contact')),
      ),
    );
  }
}
