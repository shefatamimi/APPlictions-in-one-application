/// # InquiryState
///
/// Sealed state hierarchy for [InquiryCubit].
///
/// The state machine flows:
///
/// ```
/// InquiryInitial
///    ↓ loadCities()
/// CitiesLoaded        (autocomplete ready, form enabled)
///    ↓ search…()
/// InquiryLoading      (spinner shown)
///    ↓ result
/// InquiryLoaded       (results card visible)
///    or
/// InquiryFailure      (error message shown)
/// ```
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/city_entity.dart';
import '../../domain/entities/customer_info_entity.dart';

sealed class InquiryState extends Equatable {
  const InquiryState();
}

/// Initial state before any interaction.
final class InquiryInitial extends InquiryState {
  const InquiryInitial();

  @override
  List<Object?> get props => [];
}

/// City list loaded and available for the autocomplete.
/// The inquiry form is fully ready for user input in this state.
final class CitiesLoaded extends InquiryState {
  /// Full list of cities for the autocomplete widget.
  final List<CityEntity> cities;

  const CitiesLoaded(this.cities);

  @override
  List<Object?> get props => [cities];
}

/// A search is in progress; the loading indicator is shown.
final class InquiryLoading extends InquiryState {
  const InquiryLoading();

  @override
  List<Object?> get props => [];
}

/// A search completed successfully; results are displayed.
final class InquiryLoaded extends InquiryState {
  /// The matched customer/meter record.
  final CustomerInfoEntity customer;

  /// City list retained so the search filter stays usable after a result.
  final List<CityEntity> cities;

  const InquiryLoaded({required this.customer, required this.cities});

  @override
  List<Object?> get props => [customer, cities];
}

/// A search or city-load failed.
final class InquiryFailure extends InquiryState {
  /// User-facing Arabic error message.
  final String message;

  /// City list retained (may be empty) so user can retry.
  final List<CityEntity> cities;

  const InquiryFailure({required this.message, this.cities = const []});

  @override
  List<Object?> get props => [message, cities];
}
