import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';

sealed class AuthEvent {}

class AuthSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class _AuthUserChanged extends AuthEvent {
  _AuthUserChanged(this.user);

  final AppUser? user;
}

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.user);

  final AppUser user;
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  AuthFailure(this.message);

  final String message;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(AuthInitial()) {
    _subscription = _repository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );

    on<_AuthUserChanged>((event, emit) => emit(
          event.user == null
              ? AuthUnauthenticated()
              : AuthAuthenticated(event.user!),
        ));

    on<AuthSignInRequested>((event, emit) async {
      try {
        await _repository.signInWithGoogle();
      } catch (e) {
        emit(AuthFailure('Não foi possível entrar com Google. Tente novamente.'));
      }
    });

    on<AuthSignOutRequested>((event, emit) async {
      await _repository.signOut();
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
