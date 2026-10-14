/// # InquiryCubit
///
/// Cubit managing the state of the subscription/meter inquiry screen.
///
/// ## Responsibilities
/// - Loads city list for autocomplete on screen entry.
/// - Dispatches search calls in response to user form submission.
/// - Handles clearing results and re-enabling search.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/city_entity.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/search_by_meter_usecase.dart';
import '../../domain/usecases/search_by_subscription_usecase.dart';
import 'inquiry_state.dart';

class InquiryCubit extends Cubit<InquiryState> {
  final GetCitiesUseCase _getCities;
  final SearchByMeterUseCase _searchByMeter;
  final SearchBySubscriptionUseCase _searchBySub;

  /// Cached city list — persisted between state transitions so the autocomplete
  /// remains populated after a search result or error.
  List<CityEntity> _cities = [];

  InquiryCubit({
    required GetCitiesUseCase getCitiesUseCase,
    required SearchByMeterUseCase searchByMeterUseCase,
    required SearchBySubscriptionUseCase searchBySubscriptionUseCase,
  })  : _getCities = getCitiesUseCase,
        _searchByMeter = searchByMeterUseCase,
        _searchBySub = searchBySubscriptionUseCase,
        super(const InquiryInitial());

  // ── loadCities ─────────────────────────────────────────────────────────────

  /// ## loadCities
  ///
  /// **SOAP Method**: `GetCityNumber` (via [GetCitiesUseCase])
  /// **Query**: `City:1,DataType:3`
  ///
  /// **Description**: Fetches the city/town list and emits [CitiesLoaded].
  /// Called once on screen initialisation so the autocomplete widget is
  /// immediately ready for user input.
  ///
  /// **Emits**:
  /// - [CitiesLoaded] on success.
  /// - [InquiryFailure] with an Arabic error message on network/SOAP failure
  ///   (non-blocking — the user can still manually type a city code).
  Future<void> loadCities() async {
    final result = await _getCities();
    result.fold(
      (failure) {
        // Non-fatal: form is still usable without the autocomplete.
        emit(InquiryFailure(message: failure.message, cities: const []));
        // Immediately restore a usable (empty cities) state.
        emit(CitiesLoaded(const []));
      },
      (cities) {
        _cities = cities;
        emit(CitiesLoaded(cities));
      },
    );
  }

  // ── searchByMeter ──────────────────────────────────────────────────────────

  /// ## searchByMeter
  ///
  /// **SOAP chain**: DataType:31 → DataType:13 → DataType:18
  ///
  /// **Description**: Triggers a full customer/meter lookup by the physical
  /// meter serial number entered in the meter-number field.
  ///
  /// **Parameters**:
  /// - [meterNum] — Meter serial number string.
  ///
  /// **Emits**: [InquiryLoading] → [InquiryLoaded] | [InquiryFailure].
  Future<void> searchByMeter(String meterNum) async {
    if (meterNum.trim().isEmpty) return;
    emit(const InquiryLoading());

    final result = await _searchByMeter(meterNum.trim());
    result.fold(
      (failure) =>
          emit(InquiryFailure(message: failure.message, cities: _cities)),
      (customer) => emit(InquiryLoaded(customer: customer, cities: _cities)),
    );
  }

  // ── searchBySubscription ───────────────────────────────────────────────────

  /// ## searchBySubscription
  ///
  /// **SOAP chain**: DataType:12 → DataType:31 → DataType:13 → DataType:18
  ///
  /// **Description**: Triggers a lookup by the 3-digit city code and 7-digit
  /// subscription serial number from the top row of the search form.
  ///
  /// **Parameters**:
  /// - [cityCode] — 3-digit city code.
  /// - [subSerial] — Up to 7-digit subscription serial (auto-padded).
  ///
  /// **Emits**: [InquiryLoading] → [InquiryLoaded] | [InquiryFailure].
  Future<void> searchBySubscription(String cityCode, String subSerial) async {
    if (cityCode.trim().isEmpty || subSerial.trim().isEmpty) return;
    emit(const InquiryLoading());

    final result = await _searchBySub(
      cityCode: cityCode.trim(),
      subSerial: subSerial.trim(),
    );
    result.fold(
      (failure) =>
          emit(InquiryFailure(message: failure.message, cities: _cities)),
      (customer) => emit(InquiryLoaded(customer: customer, cities: _cities)),
    );
  }

  // ── searchBy10Digit ────────────────────────────────────────────────────────

  /// ## searchBy10Digit
  ///
  /// **SOAP chain**: DataType:12 (derived from split) → DataType:31 → ...
  ///
  /// **Description**: Triggers a lookup using the full 10-digit subscription
  /// number entered in the combined subscription field.
  ///
  /// **Parameters**:
  /// - [subscription10] — 10-character subscription string.
  ///
  /// **Emits**: [InquiryLoading] → [InquiryLoaded] | [InquiryFailure].
  Future<void> searchBy10Digit(String subscription10) async {
    final s = subscription10.trim().replaceAll(RegExp(r'\s+'), '');
    if (s.isEmpty) return;
    emit(const InquiryLoading());

    // Robust handling for barcodes/inputs that might be longer than 10 digits
    // (e.g. 12, 13, 14 digits) or exactly 10 digits.
    final clean10 = s.length > 10 ? s.substring(s.length - 10) : s;
    final cityCode = clean10.length >= 3 ? clean10.substring(0, 3) : clean10;
    final subSerial = clean10.length > 3 ? clean10.substring(3) : '';

    final result = await _searchBySub(
      cityCode: cityCode,
      subSerial: subSerial,
    );
    result.fold(
      (failure) =>
          emit(InquiryFailure(message: failure.message, cities: _cities)),
      (customer) => emit(InquiryLoaded(customer: customer, cities: _cities)),
    );
  }

  // ── clearSearch ────────────────────────────────────────────────────────────

  /// ## clearSearch
  ///
  /// **Description**: Clears the current search result and returns to the
  /// [CitiesLoaded] state so the form fields can be re-enabled for a new query.
  ///
  /// Called when the user taps "مسح" (clear button).
  void clearSearch() {
    emit(CitiesLoaded(_cities));
  }
}
