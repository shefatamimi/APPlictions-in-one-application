/// # InspectionInquiryRepository
///
/// Abstract repository for the inspection process note inquiry feature.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/engineer_entity.dart';
import '../entities/operation_entity.dart';

abstract class InspectionInquiryRepository {
  /// ## getOperation
  ///
  /// **SOAP methods**: `GetWFTRANSACTIONSBiIllegalProcessNote` (DataType:2)
  /// then `GetBiIllegalProcessNote` (DataType:1), merged into one entity.
  ///
  /// **Description**: Looks up an illegal process operation by its PID and
  /// returns a fully-populated [OperationEntity].
  ///
  /// **Parameters**:
  /// - [pid] — Operation / process numeric identifier.
  ///
  /// **Returns**: `Right<OperationEntity>` on success (with `isFound = false`
  /// if no operation exists for this PID), `Left<Failure>` on network error.
  Future<Either<Failure, OperationEntity>> getOperation(String pid);

  /// ## getEngineers
  ///
  /// **SOAP Method**: `GetGenericsDataTable`
  /// **Query**: `DataType:73,Major:721`
  ///
  /// **Description**: Returns the list of all engineers available for selection
  /// in the autocomplete on the process note form.
  ///
  /// **Returns**: `Right<List<EngineerEntity>>`, `Left<Failure>` on error.
  Future<Either<Failure, List<EngineerEntity>>> getEngineers();
}
