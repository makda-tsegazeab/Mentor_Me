import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hey_tutor/models/user.dart';

void main() {
  test('User.fromMap maps fields and helper flags', () {
    final createdAt = Timestamp.fromDate(DateTime(2024, 6, 1));

    final user = User.fromMap('u1', {
      'email': 'user@example.com',
      'name': 'User One',
      'role': 'tutor',
      'age': 30,
      'subjects': ['Math'],
      'gradeLevels': ['9'],
      'minPricePerHour': 12,
      'maxPricePerHour': 20,
      'completedProfile': true,
      'createdAt': createdAt,
      'rating': 4,
      'ratingCount': 2,
    });

    expect(user.id, 'u1');
    expect(user.email, 'user@example.com');
    expect(user.name, 'User One');
    expect(user.role, 'tutor');
    expect(user.isTutor, isTrue);
    expect(user.isStudent, isFalse);
    expect(user.completedProfile, isTrue);
    expect(user.createdAt, createdAt);
    expect(user.rating, 4.0);
    expect(user.ratingCount, 2);
    expect(user.displaySubjects, 'Math');
    expect(user.displayGradeLevels, '9');
    expect(user.displayPrice, 12);
  });

  test('User display helpers return defaults when missing', () {
    final user = User.fromMap('u2', {
      'email': 'student@example.com',
      'name': 'Student',
      'role': 'student',
      'completedProfile': false,
    });

    expect(user.isStudent, isTrue);
    expect(user.displaySubjects, 'Not specified');
    expect(user.displayGradeLevels, 'Not specified');
  });
}
