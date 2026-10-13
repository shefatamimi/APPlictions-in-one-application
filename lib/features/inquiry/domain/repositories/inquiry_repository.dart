/// # InquiryRepository
///
/// Abstract repository interface for the subscription/meter inquiry feature.
///
/// Implementations must handle all network and error mapping, returning
/// `Left<Failure>` for any error and `Right<T>` for success.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/city_entity.dart';
import '../entities/customer_info_entity.dart';

abstract class InquiryRepository {
  /// ## searchByMeter
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **Query**: `DataType:31;Where:;mtrnum: and mtr.MTR_M_NUM = '{meterNum}'`
  ///
  /// **Description**: Looks up full customer and meter info by the meter serial
  /// number. Combines results from DataType:31 (meter info), DataType:13
  /// (extra subscription info), and DataType:18 (illegal notification check).
  ///
  /// **Parameters**:
  /// - [meterNum] — The physical meter serial number (e.g. `"123456789"`).
  ///
  /// **Returns**: `Right<CustomerInfoEntity>` on success,
  /// or `Left<Failure>` (ServerFailure / NetworkFailure) on error.
  Future<Either<Failure, CustomerInfoEntity>> searchByMeter(String meterNum);

  /// ## searchBySubscription
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **Query**: `DataType:12;Where: and LPAD(cmf.cusm_city,3,'0')||LPAD(cmf.CUSM_NUM,7,'0') = '{sub}';mtrnum:{sub}`
  ///
  /// **Description**: Looks up a subscription by its city code (3-digit) and
  /// serial number (7-digit), resolves the meter serial, then calls
  /// [searchByMeter] to get full details.
  ///
  /// **Parameters**:
  /// - [cityCode] — 3-digit city prefix (e.g. `"001"`).
  /// - [subSerial] — 7-digit subscription serial (e.g. `"0123456"`).
  ///
  /// **Returns**: `Right<CustomerInfoEntity>` on success,
  /// or `Left<Failure>` (ServerFailure / NetworkFailure) on error.
  Future<Either<Failure, CustomerInfoEntity>> searchBySubscription(
    String cityCode,
    String subSerial,
  );

  /// ## searchBy10Digit
  ///
  /// **SOAP Method**: `GetCustomerBillingInfoEnc`
  /// **Query**: Same as [searchBySubscription] — the 10-digit number is split
  /// into 3+7 and passed as the subscription key.
  ///
  /// **Description**: Convenience wrapper for searching by a full 10-digit
  /// subscription string (e.g. `"0010123456"`). Splits into cityCode (first 3
  /// chars) and subSerial (last 7 chars) then delegates to [searchBySubscription].
  ///
  /// **Parameters**:
  /// - [subscription10] — 10-character subscription string.
  ///
  /// **Returns**: Same as [searchBySubscription].
  Future<Either<Failure, CustomerInfoEntity>> searchBy10Digit(
    String subscription10,
  );

  /// ## getCities
  ///
  /// **SOAP Method**: `GetCityNumber`
  /// **Query**: `City:1,DataType:3`
  ///
  /// **Description**: Fetches the full list of city/town records for use in the
  /// city-name autocomplete field.
  ///
  /// **Returns**: `Right<List<CityEntity>>` with all cities,
  /// or `Left<Failure>` on network/server error.
  Future<Either<Failure, List<CityEntity>>> getCities();
}
