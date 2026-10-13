/// # Failures
///
/// Defines the sealed failure hierarchy used throughout the app.
/// All repository methods and use-cases return `Either<Failure, T>` —
/// never throw — so the presentation layer always has a typed error to display.
library;

import 'package:equatable/equatable.dart';

/// Base class for all application failures.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure produced when the device has no internet connectivity.
///
/// Raised by [NetworkInfo] before any SOAP call is attempted.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

/// Failure produced when SOAP authentication returns no valid user record
/// (empty `ID` field) or when the server is unreachable.
///
/// Arabic equivalent: "كلمة سر خاطئة او حساب غير موجود"
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'كلمة سر خاطئة او حساب غير موجود']);
}

/// Failure produced when the SOAP HTTP call throws an exception
/// (timeout, TLS error, etc.).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'خطأ في الاتصال بالخادم']);
}

/// Failure produced when the credentials are valid but the employee is not
/// entitled to a single application registered in the platform.
///
/// Arabic equivalent: "لا تملك صلاحية للدخول إلى أي تطبيق"
class NoAccessFailure extends Failure {
  const NoAccessFailure([
    super.message =
        'لا تملك صلاحية للدخول إلى أي تطبيق، يرجى مراجعة قسم الحاسوب',
  ]);
}

/// Failure produced when local secure-storage read/write fails.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطأ في التخزين المحلي']);
}

/// Failure produced when RSA encryption of the payload fails.
class EncryptionFailure extends Failure {
  const EncryptionFailure([super.message = 'خطأ في تشفير البيانات']);
}
