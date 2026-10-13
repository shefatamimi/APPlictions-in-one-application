/// # PlatformAuthCubit
///
/// Owns the single sign-on session for the whole application.
///
/// It is registered as a singleton, so every module reads the same session and
/// a logout anywhere ends it everywhere.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/platform_session.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import 'platform_auth_state.dart';

class PlatformAuthCubit extends Cubit<PlatformAuthState> {
  final SignInUseCase _signIn;
  final SignOutUseCase _signOut;
  final RestoreSessionUseCase _restoreSession;

  PlatformAuthCubit({
    required SignInUseCase signIn,
    required SignOutUseCase signOut,
    required RestoreSessionUseCase restoreSession,
  })  : _signIn = signIn,
        _signOut = signOut,
        _restoreSession = restoreSession,
        super(const PlatformAuthChecking());

  /// The live session, or `null` when nobody is signed in.
  PlatformSession? get session {
    final current = state;
    return current is PlatformAuthAuthenticated ? current.session : null;
  }

  /// ## bootstrap
  ///
  /// **Description**: Called by the splash screen. Restores a cached session so
  /// the employee logs in once, not once per launch.
  ///
  /// **Returns**: nothing — emits [PlatformAuthAuthenticated] or
  /// [PlatformAuthUnauthenticated].
  Future<void> bootstrap() async {
    final result = await _restoreSession();

    result.fold(
      (_) => emit(const PlatformAuthUnauthenticated()),
      (session) {
        if (session == null || session.grantedModuleIds.isEmpty) {
          emit(PlatformAuthUnauthenticated(
            lastUsername: session?.username ?? '',
          ));
        } else {
          emit(PlatformAuthAuthenticated(session));
        }
      },
    );
  }

  /// ## signIn
  ///
  /// **Description**: Authenticates once against the shared service and
  /// resolves the authorised applications.
  ///
  /// **Returns**: nothing — emits [PlatformAuthAuthenticated] on success or
  /// [PlatformAuthFailed] with an Arabic message.
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    emit(const PlatformAuthAuthenticating());

    final result = await _signIn(username: username, password: password);

    result.fold(
      (failure) => emit(
        PlatformAuthFailed(failure.message, lastUsername: username.trim()),
      ),
      (session) => emit(PlatformAuthAuthenticated(session)),
    );
  }

  /// Dismisses an error dialog and returns the login screen to its idle state.
  void clearError() {
    final current = state;
    if (current is PlatformAuthFailed) {
      emit(PlatformAuthUnauthenticated(lastUsername: current.lastUsername));
    }
  }

  /// ## signOut
  ///
  /// **Description**: Ends the session for every hosted application and clears
  /// the keychain.
  Future<void> signOut() async {
    final username = session?.username ?? '';
    await _signOut();
    emit(PlatformAuthUnauthenticated(lastUsername: username));
  }
}
