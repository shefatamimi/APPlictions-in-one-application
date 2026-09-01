/// # GetEngineersUseCase
///
/// Fetches the list of engineers for the inspection process note autocomplete.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/engineer_entity.dart';
import '../repositories/inspection_inquiry_repository.dart';

class GetEngineersUseCase {
  final InspectionInquiryRepository _repository;

  const GetEngineersUseCase(this._repository);

  /// ## call
  ///
  /// **SOAP Method**: `GetGenericsDataTable`
  /// **Query**: `DataType:73,Major:721`
  ///
  /// **Description**: Returns all engineer records for the process note
  /// engineer-selection autocomplete widget.
  ///
  /// **Returns**: `Right<List<EngineerEntity>>` on success, `Left<Failure>` on error.
  Future<Either<Failure, List<EngineerEntity>>> call() =>
      _repository.getEngineers();
}
