/// # SignInUseCase
///
/// The one and only authentication entry point of the platform.
///
/// It reads the application catalogue from the registry and hands it to the
/// repository, so registering a new application automatically extends the
/// permission check — no branching, no `if (moduleId == …)`.
library;

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../registry/app_registry.dart';
import '../entities/platform_session.dart';
import '../repositories/platform_auth_repository.dart';

class SignInUseCase {
  final PlatformAuthRepository _repository;

  const SignInUseCase(this._repository);

  /// ## call
  ///
  /// **Description**: Validates the input, then authenticates once against the
  /// shared REST/SOAP service and resolves the authorised applications.
  ///
  /// **Returns**: [Either]<[Failure], [PlatformSession]>.
  ///
  /// **Throws**: never.
  Future<Either<Failure, PlatformSession>> call({
    required String username,
    required String password,
  }) async {
    final user = username.trim();
    if (user.isEmpty) {
      return const Left(AuthFailure('يرجى إدخال اسم المستخدم'));
    }
    if (password.isEmpty) {
      return const Left(AuthFailure('يرجى إدخال كلمة المرور'));
    }

    return _repository.signIn(
      username: user,
      password: password,
      modules: AppRegistry.modules,
    );
  }
}
