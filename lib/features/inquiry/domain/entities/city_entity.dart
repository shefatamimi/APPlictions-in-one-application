/// # CityEntity
///
/// Immutable domain entity representing a single city/town entry as returned
/// by the `GetCityNumber` SOAP call (query `City:1,DataType:3`).
///
/// Used to populate the city-name autocomplete dropdown on the inquiry screen,
/// mirroring the original Android `CityClass` model.
library;

import 'package:equatable/equatable.dart';

class CityEntity extends Equatable {
  /// Numeric city code, used as the 3-digit prefix in subscription numbers.
  /// Corresponds to `CTYM_CODE` in the SOAP response.
  final String code;

  /// Human-readable Arabic city name.
  /// Corresponds to `CTYM_NAME` in the SOAP response.
  final String name;

  const CityEntity({required this.code, required this.name});

  @override
  List<Object?> get props => [code, name];

  @override
  String toString() => '$name ($code)';
}
