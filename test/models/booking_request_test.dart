import 'package:flutter_test/flutter_test.dart';
import 'package:hey_tutor/models/booking_request.dart';

void main() {
  test('BookingRequest toMap/fromMap round-trip', () {
    final createdAt = DateTime(2024, 1, 2, 3, 4, 5);
    final request = BookingRequest(
      id: 'req-1',
      tutorId: 'tutor-1',
      tutorName: 'Tutor A',
      studentId: 'student-1',
      studentName: 'Student A',
      subjects: ['Math', 'Science'],
      sessionsPerWeek: 2,
      hoursPerSession: 1,
      agreementNotes: 'Bring notes',
      status: 'approved',
      createdAt: createdAt,
    );

    final map = request.toMap();
    final parsed = BookingRequest.fromMap(map);

    expect(parsed.id, request.id);
    expect(parsed.tutorId, request.tutorId);
    expect(parsed.tutorName, request.tutorName);
    expect(parsed.studentId, request.studentId);
    expect(parsed.studentName, request.studentName);
    expect(parsed.subjects, request.subjects);
    expect(parsed.sessionsPerWeek, request.sessionsPerWeek);
    expect(parsed.hoursPerSession, request.hoursPerSession);
    expect(parsed.agreementNotes, request.agreementNotes);
    expect(parsed.status, request.status);
    expect(parsed.createdAt, request.createdAt);
  });

  test('BookingRequest.fromMap applies defaults', () {
    final createdAt = DateTime(2024, 1, 1);
    final parsed = BookingRequest.fromMap({
      'id': 'req-2',
      'tutorId': 'tutor-2',
      'tutorName': 'Tutor B',
      'studentId': 'student-2',
      'studentName': 'Student B',
      'createdAt': createdAt.millisecondsSinceEpoch,
    });

    expect(parsed.subjects, isEmpty);
    expect(parsed.sessionsPerWeek, 1);
    expect(parsed.hoursPerSession, 1);
    expect(parsed.agreementNotes, '');
    expect(parsed.status, 'pending');
    expect(parsed.createdAt, createdAt);
  });
}
