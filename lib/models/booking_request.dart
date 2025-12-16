class BookingRequest {
  final String id;
  final String tutorId;
  final String tutorName;
  final String studentId;
  final String studentName;
  final List<String> subjects;
  final int sessionsPerWeek;
  final int hoursPerSession;
  final String agreementNotes;
  final String status; // pending, approved, declined
  final DateTime createdAt;

  BookingRequest({
    required this.id,
    required this.tutorId,
    required this.tutorName,
    required this.studentId,
    required this.studentName,
    required this.subjects,
    required this.sessionsPerWeek,
    required this.hoursPerSession,
    this.agreementNotes = '',
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'studentId': studentId,
      'studentName': studentName,
      'subjects': subjects,
      'sessionsPerWeek': sessionsPerWeek,
      'hoursPerSession': hoursPerSession,
      'agreementNotes': agreementNotes,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BookingRequest.fromMap(Map<String, dynamic> map) {
    return BookingRequest(
      id: map['id'],
      tutorId: map['tutorId'],
      tutorName: map['tutorName'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      subjects: List<String>.from(map['subjects'] ?? []),
      sessionsPerWeek: map['sessionsPerWeek'] ?? 1,
      hoursPerSession: map['hoursPerSession'] ?? 1,
      agreementNotes: map['agreementNotes'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
