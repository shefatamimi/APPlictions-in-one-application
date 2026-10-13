/// # SubmissionRepository
///
/// Abstract contract for fetching illegal-notification records assigned to
/// the current employee's workshop (`GetIllegalNotification` DataType:18).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/submission_entity.dart';

abstract class SubmissionRepository {
  /// Fetches all [SubmissionEntity] records for the given [workshopId].
  ///
  /// **SOAP**: `GetIllegalNotification`
  /// **Query**: `DataType:18;Where: and WORKSHOP_ID = {workshopId}`
  Future<Either<Failure, List<SubmissionEntity>>> getSubmissions(
      String workshopId);
}
