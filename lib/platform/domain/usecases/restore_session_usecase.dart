/// # RestoreSessionUseCase
///
/// Used by the splash screen to decide between the login screen and the
/// dashboard, giving the platform its "log in once" behaviour.
library;

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../entities/platform_session.dart';
import '../repositories/platform_auth_repository.dart';

class RestoreSessionUseCase {
  final PlatformAuthRepository _repository;

  const RestoreSessionUseCase(this._repository);

  /// **Returns**: [Right] with the cached session, [Right]`(null)` when there is
  /// none, or [Left] on a storage error.
  Future<Either<Failure, PlatformSession?>> call() =>
      _repository.restoreSession();
}
