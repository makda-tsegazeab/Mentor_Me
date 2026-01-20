import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'tutor', 'student', 'parent'
  final int? age;
  final String? sex;
  final String? city;
  final String? qualification;
  final List<String>? subjects;
  final List<String>? gradeLevels;
  final int? hoursPerDay;
  final int? daysPerWeek;
  final double? minPricePerHour;
  final double? maxPricePerHour;
  final String? preferredTutorGender;
  final bool? available;
  final bool? verified;
  final String? idType;
  final String? idNumber;
  final String? idExpiryDate;
  final String? profileImage;
  final String? idFront;
  final String? idBack;
  final bool completedProfile;
  final Timestamp? createdAt;
  final double? rating;
  final int? ratingCount;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.age,
    this.sex,
    this.city,
    this.qualification,
    this.subjects,
    this.gradeLevels,
    this.hoursPerDay,
    this.daysPerWeek,
    this.minPricePerHour,
    this.maxPricePerHour,
    this.preferredTutorGender,
    this.available,
    this.verified,
    this.idType,
    this.idNumber,
    this.idExpiryDate,
    this.profileImage,
    this.idFront,
    this.idBack,
    required this.completedProfile,
    this.createdAt,
    this.rating,
    this.ratingCount,
  });

  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      age: data['age'],
      sex: data['sex'],
      city: data['city'],
      qualification: data['qualification'],
      subjects:
          data['subjects'] != null ? List<String>.from(data['subjects']) : null,
      gradeLevels: data['gradeLevels'] != null
          ? List<String>.from(data['gradeLevels'])
          : null,
      hoursPerDay: data['hoursPerDay'],
      daysPerWeek: data['daysPerWeek'],
      minPricePerHour: data['minPricePerHour'] != null
          ? data['minPricePerHour'].toDouble()
          : null,
      maxPricePerHour: data['maxPricePerHour'] != null
          ? data['maxPricePerHour'].toDouble()
          : null,
      preferredTutorGender: data['preferredTutorGender'],
      available: data['available'],
      verified: data['verified'] ?? false,
      idType: data['idType'],
      idNumber: data['idNumber'],
      idExpiryDate: data['idExpiryDate'],
      profileImage: data['profileImage'],
      idFront: data['idFront'],
      idBack: data['idBack'],
      completedProfile: data['completedProfile'] ?? false,
      createdAt: data['createdAt'],
      rating:
          data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      ratingCount: data['ratingCount'],
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User.fromMap(doc.id, data);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'age': age,
        'sex': sex,
        'city': city,
        'qualification': qualification,
        'subjects': subjects,
        'gradeLevels': gradeLevels,
        'hoursPerDay': hoursPerDay,
        'daysPerWeek': daysPerWeek,
        'minPricePerHour': minPricePerHour,
        'maxPricePerHour': maxPricePerHour,
        'preferredTutorGender': preferredTutorGender,
        'available': available,
        'verified': verified,
        'idType': idType,
        'idNumber': idNumber,
        'idExpiryDate': idExpiryDate,
        'profileImage': profileImage,
        'idFront': idFront,
        'idBack': idBack,
        'completedProfile': completedProfile,
        'createdAt': createdAt,
        'rating': rating,
        'ratingCount': ratingCount,
      };

  // Helper methods
  bool get isTutor => role == 'tutor';
  bool get isStudent => role == 'student';
  bool get isParent => role == 'parent';

  // Get display price - for tutors only
  double? get displayPrice => minPricePerHour;

  // Get display subjects
  String get displaySubjects {
    if (subjects == null || subjects!.isEmpty) return 'Not specified';
    return subjects!.join(', ');
  }

  // Get display grade levels
  String get displayGradeLevels {
    if (gradeLevels == null || gradeLevels!.isEmpty) return 'Not specified';
    return gradeLevels!.join(', ');
  }
}
