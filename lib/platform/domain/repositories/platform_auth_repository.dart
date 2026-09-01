/// # PlatformAuthRepository
///
/// Domain contract for the single sign-on. The presentation layer never sees a
/// SOAP envelope, an `app_id` or a keychain key — only these three operations.
library;

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../entities/app_module.dart';
import '../entities/platform_session.dart';

abstract class PlatformAuthRepository {
  /// ## signIn
  ///
  /// **Description**: Authenticates the employee once and resolves, in the same
  /// round trip set, which of [modules] the server authorises.
  ///
  /// **Returns**: [Either]<[Failure], [PlatformSession]>
  /// - [Right] with the session (employee + granted application ids).
  /// - [Left] [AuthFailure] when the credentials are rejected everywhere.
  /// - [Left] [ServerFailure] / [NetworkFailure] on transport problems.
  Future<Either<Failure, PlatformSession>> signIn({
    required String username,
    required String password,
    required List<AppModule> modules,
  });

  /// ## restoreSession
  ///
  /// **Description**: Reads the cached session so a returning user lands on the
  /// dashboard without typing credentials again.
  ///
  /// **Returns**: [Right] with the session, [Right]`(null)` when no session is
  /// cached, [Left] [CacheFailure] when the keychain read fails.
  Future<Either<Failure, PlatformSession?>> restoreSession();

  /// ## signOut
  ///
  /// **Description**: Clears the cached session and credentials.
  Future<Either<Failure, Unit>> signOut();
}
