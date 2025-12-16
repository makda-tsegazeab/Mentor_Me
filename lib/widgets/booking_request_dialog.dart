import 'package:flutter/material.dart';
import '../models/booking_request.dart';
import '../services/interaction_logger.dart';

class BookingRequestDialog extends StatefulWidget {
  final String tutorId;
  final String tutorName;
  final String studentId;
  final String studentName;
  final Future<void> Function(BookingRequest) onBookingRequest;

  const BookingRequestDialog({
    super.key,
    required this.tutorId,
    required this.tutorName,
    required this.studentId,
    required this.studentName,
    required this.onBookingRequest,
  });

  @override
  State<BookingRequestDialog> createState() => _BookingRequestDialogState();
}

class _BookingRequestDialogState extends State<BookingRequestDialog> {
  final List<String> _selectedSubjects = [];
  final _agreementNotesController = TextEditingController();
  int _sessionsPerWeek = 2;
  int _hoursPerSession = 2;
  bool _submitting = false;

  final List<String> _availableSubjects = const [
    'Mathematics',
    'English',
    'Physics',
    'Chemistry',
    'Biology',
    'ICT',
    'Amharic',
    'Tigrigna',
  ];

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedSubjects.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final booking = BookingRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tutorId: widget.tutorId,
        tutorName: widget.tutorName,
        studentId: widget.studentId,
        studentName: widget.studentName,
        subjects: List<String>.from(_selectedSubjects),
        sessionsPerWeek: _sessionsPerWeek,
        hoursPerSession: _hoursPerSession,
        agreementNotes: _agreementNotesController.text.trim(),
        createdAt: DateTime.now(),
      );
      await widget.onBookingRequest(booking);
      InteractionLogger.recordLearnerInteraction(
        learnerId: widget.studentId,
        tutorId: widget.tutorId,
        event: 'request',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _agreementNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.handshake, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Start Tutoring Relationship'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formal agreement with ${widget.tutorName}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Text(
              'Subjects to be taught:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSubjects.map((subject) {
                final isSelected = _selectedSubjects.contains(subject);
                return FilterChip(
                  label: Text(subject),
                  selected: isSelected,
                  onSelected: (_) => _toggleSubject(subject),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Sessions per week:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _sessionsPerWeek,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sessionsPerWeek = value);
                    }
                  },
                  items: [1, 2, 3, 4, 5, 6, 7]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value session${value > 1 ? 's' : ''}'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Hours per session:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _hoursPerSession,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _hoursPerSession = value);
                    }
                  },
                  items: [1, 2, 3, 4]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value hour${value > 1 ? 's' : ''}'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Additional agreement notes (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: _agreementNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any specific terms or expectations...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Booking Request'),
        ),
      ],
    );
  }
}
