import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase.FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  
  final StreamController<AppUser?> _mockUserStreamController = StreamController<AppUser?>.broadcast();
  AppUser? _mockUser;
  String? _pendingPhone;

  FirebaseAuthRepository({
    firebase.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = _isFirebaseAvailable() ? (firebaseAuth ?? firebase.FirebaseAuth.instance) : null,
        _googleSignIn = _isFirebaseAvailable() ? (googleSignIn ?? GoogleSignIn()) : null;

  static bool _isFirebaseAvailable() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get isFirebaseEnabled => _firebaseAuth != null;

  AppUser? _mapFirebaseUser(firebase.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Cosmic Explorer',
      phoneNumber: user.phoneNumber,
    );
  }

  @override
  Stream<AppUser?> get user {
    if (isFirebaseEnabled) {
      return _firebaseAuth!.authStateChanges().map(_mapFirebaseUser);
    } else {
      return _mockUserStreamController.stream;
    }
  }

  @override
  AppUser? get currentUser {
    if (isFirebaseEnabled) {
      return _mapFirebaseUser(_firebaseAuth!.currentUser);
    } else {
      return _mockUser;
    }
  }

  @override
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final auth = _firebaseAuth;
    if (auth != null) {
      try {
        final firebase.UserCredential userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(displayName);
          await userCredential.user!.reload();
        }
        return _mapFirebaseUser(auth.currentUser);
      } catch (e) {
        throw Exception("Sign-Up failed: $e");
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      _mockUser = AppUser(
        uid: "mock_email_id_${email.hashCode}",
        email: email,
        displayName: displayName,
      );
      _mockUserStreamController.add(_mockUser);
      return _mockUser;
    }
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth != null) {
      try {
        final firebase.UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _mapFirebaseUser(userCredential.user);
      } catch (e) {
        throw Exception("Sign-In failed: $e");
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      _mockUser = AppUser(
        uid: "mock_email_id_${email.hashCode}",
        email: email,
        displayName: "Earth Traveler",
      );
      _mockUserStreamController.add(_mockUser);
      return _mockUser;
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    if (isFirebaseEnabled) {
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final firebase.OAuthCredential credential = firebase.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final firebase.UserCredential userCredential = await _firebaseAuth!.signInWithCredential(credential);
        return _mapFirebaseUser(userCredential.user);
      } catch (e) {
        throw Exception("Google Sign-In failed: $e");
      }
    } else {
      // Simulate Google Sign-In delay
      await Future.delayed(const Duration(milliseconds: 800));
      _mockUser = AppUser(
        uid: "mock_google_id_100",
        email: "cosmic.goddess@retrogalaxy.com",
        displayName: "Celesta Astro",
      );
      _mockUserStreamController.add(_mockUser);
      return _mockUser;
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(firebase.FirebaseAuthException e) verificationFailed,
    required void Function(firebase.PhoneAuthCredential credential) verificationCompleted,
  }) async {
    if (isFirebaseEnabled) {
      try {
        await _firebaseAuth!.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      } catch (e) {
        throw Exception("Phone verification failed: $e");
      }
    } else {
      // Simulate Phone Verification OTP sending delay
      await Future.delayed(const Duration(milliseconds: 800));
      _pendingPhone = phoneNumber;
      codeSent("mock_verification_id_200", null);
    }
  }

  @override
  Future<AppUser?> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    if (isFirebaseEnabled) {
      try {
        final firebase.PhoneAuthCredential credential = firebase.PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        final firebase.UserCredential userCredential = await _firebaseAuth!.signInWithCredential(credential);
        return _mapFirebaseUser(userCredential.user);
      } catch (e) {
        throw Exception("Phone Sign-In verification failed: $e");
      }
    } else {
      // Simulate confirmation check
      await Future.delayed(const Duration(milliseconds: 600));
      if (smsCode == "123456" || smsCode.length == 6) {
        _mockUser = AppUser(
          uid: "mock_phone_id_300",
          email: "",
          displayName: "Space Wanderer",
          phoneNumber: _pendingPhone ?? "+15555554321",
        );
        _mockUserStreamController.add(_mockUser);
        return _mockUser;
      } else {
        throw Exception("Invalid SMS verification code. Use 123456 or any 6-digit code.");
      }
    }
  }

  @override
  Future<void> signOut() async {
    if (isFirebaseEnabled) {
      await _googleSignIn!.signOut();
      await _firebaseAuth!.signOut();
    } else {
      _mockUser = null;
      _mockUserStreamController.add(null);
    }
  }
}
