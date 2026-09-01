/// # GetSubmissionsUseCase
///
/// Fetches all illegal-notification records for the logged-in employee's
/// workshop by invoking [SubmissionRepository.getSubmissions].
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/submission_entity.dart';
import '../repositories/submission_repository.dart';

class GetSubmissionsUseCase {
  final SubmissionRepository _repository;
  const GetSubmissionsUseCase(this._repository);

  /// ## call
  ///
  /// **Parameter**: [workshopId] — The current user's workshop ID
  /// (from `Employee.workshopNumber` / SharedPreferences `WRK_SHOP_NUM`).
  ///
  /// **Returns**: `Right<List<SubmissionEntity>>` on success,
  /// `Left<Failure>` on error.
  Future<Either<Failure, List<SubmissionEntity>>> call(String workshopId) =>
      _repository.getSubmissions(workshopId);
}
