/// # GetCitiesUseCase
///
/// Fetches the full city/town list for the inquiry screen autocomplete.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/city_entity.dart';
import '../repositories/inquiry_repository.dart';

class GetCitiesUseCase {
  final InquiryRepository _repository;

  const GetCitiesUseCase(this._repository);

  /// ## call
  ///
  /// **SOAP Method**: `GetCityNumber`
  /// **Query**: `City:1,DataType:3`
  ///
  /// **Description**: Returns the list of all cities/towns for populating the
  /// city-name autocomplete widget on the inquiry screen.
  ///
  /// **Returns**: `Right<List<CityEntity>>` on success,
  /// `Left<Failure>` on any error.
  Future<Either<Failure, List<CityEntity>>> call() => _repository.getCities();
}
