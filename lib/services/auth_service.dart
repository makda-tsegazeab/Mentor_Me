import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> login(String email, String password, String role) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (doc.exists && doc.data()!['role'] == role) {
        return User.fromJson({'id': userCredential.user!.uid, ...doc.data()!});
      }
      throw Exception('Role mismatch');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<User?> signup(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
      );
      await _firestore.collection('users').doc(user.id).set(user.toJson());
      if (role == 'tutor') {
        await _firestore.collection('tutors').doc(user.id).set({
          'userId': user.id,
          'name': name,
          'city': '',
          'subjects': [],
          'bio': '',
          'rate': 0.0,
        });
      }
      return user;
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return User.fromJson({'id': firebaseUser.uid, ...doc.data()!});
      }
    }
    return null;
  }
}
