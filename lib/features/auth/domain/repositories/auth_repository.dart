import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
  });
}

abstract class AuthRepository {
  Stream<AppUser?> get user;
  AppUser? get currentUser;
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<AppUser?> signInWithGoogle();
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(firebase.FirebaseAuthException e) verificationFailed,
    required void Function(firebase.PhoneAuthCredential credential) verificationCompleted,
  });
  Future<AppUser?> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  });
  Future<void> signOut();
}
