import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/repositories/auth_repository.dart';

// EVENTS
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInWithGoogle extends AuthEvent {}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignInRequested({required this.email, required this.password});
}

class AuthVerifyPhoneNumber extends AuthEvent {
  final String phoneNumber;
  AuthVerifyPhoneNumber(this.phoneNumber);
}

class AuthConfirmOTP extends AuthEvent {
  final String verificationId;
  final String smsCode;
  AuthConfirmOTP({required this.verificationId, required this.smsCode});
}

class AuthSignOut extends AuthEvent {}

class AuthContinueOffline extends AuthEvent {}

class _AuthUserChanged extends AuthEvent {
  final AppUser? user;
  _AuthUserChanged(this.user);
}

// STATES
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {
  final String verificationId;
  AuthCodeSent(this.verificationId);
}

class AuthSuccess extends AuthState {
  final AppUser user;
  AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String errorMessage;
  AuthFailure(this.errorMessage);
}

class AuthUnauthenticated extends AuthState {}

// BLOC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _userSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignInWithGoogle>(_onAuthSignInWithGoogle);
    on<AuthVerifyPhoneNumber>(_onAuthVerifyPhoneNumber);
    on<AuthConfirmOTP>(_onAuthConfirmOTP);
    on<AuthSignOut>(_onAuthSignOut);
    on<AuthContinueOffline>(_onAuthContinueOffline);
    on<_AuthUserChanged>(_onAuthUserChanged);

    // Track real-time Auth changes
    _userSubscription = _authRepository.user.listen((user) {
      add(_AuthUserChanged(user));
    });
  }

  void _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthSuccess(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignInWithGoogle(AuthSignInWithGoogle event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthVerifyPhoneNumber(AuthVerifyPhoneNumber event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final completer = Completer<void>();

    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        codeSent: (String verId, int? resendToken) {
          emit(AuthCodeSent(verId));
          completer.complete();
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          emit(AuthFailure(e.message ?? "Phone verification failed"));
          completer.complete();
        },
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          completer.complete();
        },
      );

      await completer.future;
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthConfirmOTP(AuthConfirmOTP event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithPhoneCredential(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthFailure("Verification failed - null user returned"));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onAuthContinueOffline(AuthContinueOffline event, Emitter<AuthState> emit) {
    emit(AuthSuccess(AppUser(
      uid: 'local_offline_user',
      email: '',
      displayName: 'Guest',
      phoneNumber: null,
    )));
  }

  void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthSuccess(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
