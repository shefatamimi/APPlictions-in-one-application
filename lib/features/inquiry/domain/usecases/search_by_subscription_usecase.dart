/// # SearchBySubscriptionUseCase
///
/// Orchestrates customer lookup by city code + subscription serial number.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/customer_info_entity.dart';
import '../repositories/inquiry_repository.dart';

class SearchBySubscriptionUseCase {
  final InquiryRepository _repository;

  const SearchBySubscriptionUseCase(this._repository);

  /// ## call
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc` (DataType:12 → DataType:31 → DataType:13 → DataType:18)
  ///
  /// **Description**: Looks up a customer by their city code and 7-digit
  /// subscription serial. First resolves to the meter serial number, then
  /// fetches full customer details.
  ///
  /// **Parameters**:
  /// - [cityCode] — 3-digit numeric city prefix.
  /// - [subSerial] — 7-digit subscription serial.
  ///
  /// **Returns**: `Right<CustomerInfoEntity>` on success,
  /// `Left<Failure>` on any error.
  Future<Either<Failure, CustomerInfoEntity>> call({
    required String cityCode,
    required String subSerial,
  }) =>
      _repository.searchBySubscription(cityCode.trim(), subSerial.trim());
}
