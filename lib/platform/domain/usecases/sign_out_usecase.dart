/// # SignOutUseCase
///
/// Ends the single sign-on session for every hosted application at once.
library;

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../repositories/platform_auth_repository.dart';

class SignOutUseCase {
  final PlatformAuthRepository _repository;

  const SignOutUseCase(this._repository);

  /// **Returns**: [Right]`(unit)` once the keychain is cleared.
  Future<Either<Failure, Unit>> call() => _repository.signOut();
}
