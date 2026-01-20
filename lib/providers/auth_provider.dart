import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? error;

  Future<User?> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'completedProfile': false,
          'suspended': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      error = e.message;
      rethrow;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<User?> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data()?['role'] != role) {
        await _auth.signOut();
        throw Exception('Role mismatch. Please select the correct role.');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      error = e.message;
      rethrow;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<User?> signInWithGoogle({
    required String role,
    String? nameOverride,
  }) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      final userDoc = _firestore.collection('users').doc(user.uid);
      final doc = await userDoc.get();
      final requestedRole = role.trim().toLowerCase();
      final name = (nameOverride?.trim().isNotEmpty ?? false)
          ? nameOverride!.trim()
          : (user.displayName ?? 'User');

      if (!doc.exists) {
        await userDoc.set({
          'name': name,
          'email': user.email ?? '',
          'role': requestedRole,
          'completedProfile': false,
          'suspended': false,
          'createdAt': FieldValue.serverTimestamp(),
          'profileImage': user.photoURL,
        });
      } else {
        final data = doc.data();
        final existingRole = (data?['role'] ?? '').toString().trim();
        if (existingRole.isEmpty) {
          await userDoc.set({'role': requestedRole}, SetOptions(merge: true));
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      error = e.message;
      rethrow;
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
