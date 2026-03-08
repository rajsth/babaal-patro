import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(FirebaseAuth.instance.currentUser) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      state = user;
    });
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: use Firebase Auth popup flow directly
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
        return true;
      }
      // Mobile: use google_sign_in package
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
      state = null;
    } catch (e) {
      state = FirebaseAuth.instance.currentUser;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>(
  (ref) => AuthNotifier(),
);
