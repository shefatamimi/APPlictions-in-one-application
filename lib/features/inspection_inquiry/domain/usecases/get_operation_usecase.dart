/// # GetOperationUseCase
///
/// Fetches an illegal inspection process operation by its PID.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/operation_entity.dart';
import '../repositories/inspection_inquiry_repository.dart';

class GetOperationUseCase {
  final InspectionInquiryRepository _repository;

  const GetOperationUseCase(this._repository);

  /// ## call
  ///
  /// **SOAP chain**: `GetWFTRANSACTIONSBiIllegalProcessNote` (DataType:2)
  ///                 → `GetBiIllegalProcessNote` (DataType:1)
  ///
  /// **Description**: Looks up the operation identified by [pid]. Merges data
  /// from two SOAP calls into a single [OperationEntity].
  ///
  /// **Parameters**:
  /// - [pid] — Numeric operation/process identifier.
  ///
  /// **Returns**: `Right<OperationEntity>` (isFound may be false if pid doesn't
  /// exist), or `Left<Failure>` on network/SOAP failure.
  Future<Either<Failure, OperationEntity>> call(String pid) =>
      _repository.getOperation(pid.trim());
}
