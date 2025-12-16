class TutoringRelationship {
  String id;
  String tutorId;
  String studentId;
  String tutorName;
  String studentName;
  String status; // 'active', 'cancelled', 'completed'
  DateTime startDate;
  DateTime? endDate;
  List<String> subjects;
  int sessionsPerWeek;
  int hoursPerSession;
  String agreementNotes;
  DateTime createdAt;

  TutoringRelationship({
    required this.id,
    required this.tutorId,
    required this.studentId,
    required this.tutorName,
    required this.studentName,
    this.status = 'active',
    required this.startDate,
    this.endDate,
    required this.subjects,
    this.sessionsPerWeek = 1,
    this.hoursPerSession = 1,
    this.agreementNotes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tutorId': tutorId,
      'studentId': studentId,
      'tutorName': tutorName,
      'studentName': studentName,
      'status': status,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'subjects': subjects,
      'sessionsPerWeek': sessionsPerWeek,
      'hoursPerSession': hoursPerSession,
      'agreementNotes': agreementNotes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TutoringRelationship.fromMap(Map<String, dynamic> map) {
    return TutoringRelationship(
      id: map['id'],
      tutorId: map['tutorId'],
      studentId: map['studentId'],
      tutorName: map['tutorName'],
      studentName: map['studentName'],
      status: map['status'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      subjects: List<String>.from(map['subjects']),
      sessionsPerWeek: map['sessionsPerWeek'] ?? 1,
      hoursPerSession: map['hoursPerSession'] ?? 1,
      agreementNotes: map['agreementNotes'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
