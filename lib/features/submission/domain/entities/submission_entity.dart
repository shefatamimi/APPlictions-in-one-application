/// # SubmissionEntity
///
/// Domain entity representing a single illegal-notification record as returned
/// by `GetIllegalNotification` with `DataType:18;Where: and WORKSHOP_ID = {id}`.
///
/// Mirrors the Android `SubmittionClass` model used in `SubmitionActivity`.
library;

import 'package:equatable/equatable.dart';

class SubmissionEntity extends Equatable {
  /// Unique record ID (ID).
  final String id;

  /// 3-digit city code (CITY_ID).
  final String cityId;

  /// 7-digit customer/subscription serial (CUST_ID).
  /// `"0000000"` means the notification has no linked subscription.
  final String custId;

  /// Customer display name (CUST_NAME).
  final String custName;

  /// Unsubscribed-customer name when [custId] is `"0000000"` (UNCUST_NAME).
  final String uncustName;

  /// Street address (ADDRESS).
  final String address;

  /// Customer mobile number (MOBILE).
  final String mobile;

  /// Physical meter serial number (CUSM_M_NUM).
  final String meterNum;

  /// Last meter reading (CUSM_M_LREAD).
  final String lastReading;

  /// Supervisor / head notes (HEAD_NOTES).
  final String headNotes;

  /// Engineer notes (ENG_NOTES).
  final String engNotes;

  /// Notification step / status code (ILL_STEP).
  final String illStep;

  /// Process PID for chaining to [InspectionInquiryPage] (PID).
  final String pid;

  /// Date the illegal notification was filed (ILLEGAL_DATE).
  final String illegalDate;

  /// Employee name who filed the notification (EMP_NAME).
  final String empName;

  /// Workshop name (WORKSHOP_NAME).
  final String workshopName;

  /// Transaction request type code (TRANS_REQUST_TYPE).
  final String transRequestType;

  /// GPS X coordinate (CUSM_X_POSITION). Empty if unavailable.
  final String posX;

  /// GPS Y coordinate (CUSM_Y_POSITION). Empty if unavailable.
  final String posY;

  const SubmissionEntity({
    required this.id,
    required this.cityId,
    required this.custId,
    required this.custName,
    required this.uncustName,
    required this.address,
    required this.mobile,
    required this.meterNum,
    required this.lastReading,
    required this.headNotes,
    required this.engNotes,
    required this.illStep,
    required this.pid,
    required this.illegalDate,
    required this.empName,
    required this.workshopName,
    required this.transRequestType,
    required this.posX,
    required this.posY,
  });

  /// `true` when this notification is linked to a real subscription.
  /// Mirrors `CUST_ID != "0000000"` check in the original Android adapter.
  bool get hasSubscription => custId.isNotEmpty && custId != '0000000';

  /// Full 10-digit subscription number: city (3 digits) + serial (7 digits).
  String get subscriptionNumber => cityId + custId;

  /// Display name: customer name if subscribed, uncust name otherwise.
  String get displayName => hasSubscription
      ? custName
      : (uncustName.isNotEmpty ? uncustName : custName);

  @override
  List<Object?> get props => [
        id,
        cityId,
        custId,
        custName,
        uncustName,
        address,
        mobile,
        meterNum,
        lastReading,
        headNotes,
        engNotes,
        illStep,
        pid,
        illegalDate,
        empName,
        workshopName,
        transRequestType,
        posX,
        posY,
      ];
}
