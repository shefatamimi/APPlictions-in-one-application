/// # SearchByMeterUseCase
///
/// Orchestrates the customer lookup by meter serial number.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/customer_info_entity.dart';
import '../repositories/inquiry_repository.dart';

class SearchByMeterUseCase {
  final InquiryRepository _repository;

  const SearchByMeterUseCase(this._repository);

  /// ## call
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc` (DataType:31 → DataType:13 → DataType:18)
  ///
  /// **Description**: Fetches full customer and meter details by the physical
  /// meter serial number.  The repository implementation chains three SOAP
  /// calls internally and returns a fully-populated entity.
  ///
  /// **Parameters**:
  /// - [meterNum] — Physical meter serial number.
  ///
  /// **Returns**: `Right<CustomerInfoEntity>` on success,
  /// `Left<Failure>` on any error.
  Future<Either<Failure, CustomerInfoEntity>> call(String meterNum) =>
      _repository.searchByMeter(meterNum.trim());
}
