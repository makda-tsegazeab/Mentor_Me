import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tutor.dart';

class TutorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Tutor>> getTutors({String? city, String? subject}) async {
    try {
      Query query = _firestore.collection('tutors');
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }
      if (subject != null && subject.isNotEmpty) {
        query = query.where('subjects', arrayContains: subject);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => Tutor.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tutors: $e');
    }
  }
}
