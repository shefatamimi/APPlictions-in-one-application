/// # OperationEntity
///
/// Immutable domain entity representing an illegal inspection process operation,
/// combining data from:
///
/// - `GetWFTRANSACTIONSBiIllegalProcessNote` (DataType:2) — city, subscription
/// - `GetBiIllegalProcessNote` (DataType:1) — engineer, workshop, notes, stamp
///
/// Mirrors the original Android `OperationClass` model.
library;

import 'package:equatable/equatable.dart';

class OperationEntity extends Equatable {
  /// Operation / process PID searched for.
  final String pid;

  /// City/town of the subscription (CITY from DataType:2).
  final String city;

  /// Subscription number (CUSTOMER_ID from DataType:2).
  final String subscriptionNum;

  /// Assigned engineer name (ENG_EMP_NAME from DataType:1).
  final String engineerName;

  /// Assigned engineer employee number (ENG_EMP_NUMBER from DataType:1).
  final String engineerNumber;

  /// Assigned workshop name (WRK_NAME from DataType:1).
  final String workshopName;

  /// Assigned workshop number (WRK_NO from DataType:1).
  final String workshopNumber;

  /// Engineer's illegal process note / remarks (ENG_ILL_NOTE from DataType:1).
  final String engineerNote;

  /// Stamp / seal number (STAMP_NUM from DataType:1).
  final String stampNumber;

  /// General operation notes (ILL_NOTES from DataType:1).
  final String notes;

  /// Date of the process note (D from DataType:1).
  final String date;

  /// Engineer approval state (ENG_APP_APPROVAL_STATE from DataType:1).
  final String approvalState;

  /// Whether the operation record was found and is complete.
  final bool isFound;

  /// Whether the engineer is already assigned (engineerName is non-empty).
  bool get isAssigned => engineerName.isNotEmpty && workshopName.isNotEmpty;

  const OperationEntity({
    required this.pid,
    required this.city,
    required this.subscriptionNum,
    required this.engineerName,
    required this.engineerNumber,
    required this.workshopName,
    required this.workshopNumber,
    required this.engineerNote,
    required this.stampNumber,
    required this.notes,
    required this.date,
    required this.approvalState,
    required this.isFound,
  });

  @override
  List<Object?> get props => [
        pid,
        city,
        subscriptionNum,
        engineerName,
        engineerNumber,
        workshopName,
        workshopNumber,
        engineerNote,
        stampNumber,
        notes,
        date,
        approvalState,
        isFound,
      ];
}
