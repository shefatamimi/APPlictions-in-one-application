/// # CustomerInfoEntity
library;

import 'package:equatable/equatable.dart';

class CustomerInfoEntity extends Equatable {
  final String customerName;
  final String subscriptionSerial;
  final String cityCode;
  final String cityName;
  final String address;
  final String meterKind;
  final String meterModel;
  final String meterSerialNum;
  final bool isSmart;
  final String phase;
  final String subscriptionKind;
  final String subscriptionType;
  final String lastReading;
  final String lastReadingDate;
  final String supportPhone;
  final String regionCode;
  final String readerName;
  final String? posX;
  final String? posY;

  /// CUSM_COSTTIME_FLAG == "1"
  final bool hasTimeOfUse;

  /// REN == "1" (Renewable Energy)
  final bool isRenewable;

  final List<String> timeReadings;

  static const List<String> timeReadingLabels = [
    'أخر قراءة للعداد لوقت الذروة',
    'أخر قراءة للعداد لوقت خارج الذروة',
    'أخر قراءة للعداد لوقت خارج الذروة جزئي 1',
    'أخر قراءة للعداد لوقت خارج الذروة جزئي 2',
    'أخر قراءة للعداد للطاقة المصدرة لوقت الذروة',
    'أخر قراءة للعداد للطاقة المصدرة لوقت خارج الذروة',
    'أخر قراءة للعداد للطاقة المصدرة لوقت الذروة جزئي 1',
    'أخر قراءة للعداد للطاقة المصدرة لوقت الذروة جزئي 2',
  ];

  final bool hasIllegalNotification;

  const CustomerInfoEntity({
    required this.customerName,
    required this.subscriptionSerial,
    required this.cityCode,
    required this.cityName,
    required this.address,
    required this.meterKind,
    required this.meterModel,
    required this.meterSerialNum,
    required this.isSmart,
    required this.phase,
    required this.subscriptionKind,
    required this.subscriptionType,
    required this.lastReading,
    required this.lastReadingDate,
    required this.supportPhone,
    required this.regionCode,
    required this.readerName,
    this.posX,
    this.posY,
    required this.hasTimeOfUse,
    this.isRenewable = false,
    required this.timeReadings,
    this.hasIllegalNotification = false,
  });

  String get formattedSubscription =>
      cityCode.padLeft(3, '0') + subscriptionSerial.padLeft(7, '0');

  bool get hasLocation =>
      posX != null &&
      posY != null &&
      posX!.isNotEmpty &&
      posY!.isNotEmpty &&
      posX != '-1' &&
      posY != '-1';

  CustomerInfoEntity withNotification(bool value) => CustomerInfoEntity(
        customerName: customerName,
        subscriptionSerial: subscriptionSerial,
        cityCode: cityCode,
        cityName: cityName,
        address: address,
        meterKind: meterKind,
        meterModel: meterModel,
        meterSerialNum: meterSerialNum,
        isSmart: isSmart,
        phase: phase,
        subscriptionKind: subscriptionKind,
        subscriptionType: subscriptionType,
        lastReading: lastReading,
        lastReadingDate: lastReadingDate,
        supportPhone: supportPhone,
        regionCode: regionCode,
        readerName: readerName,
        posX: posX,
        posY: posY,
        hasTimeOfUse: hasTimeOfUse,
        isRenewable: isRenewable,
        timeReadings: timeReadings,
        hasIllegalNotification: value,
      );

  @override
  List<Object?> get props => [
        customerName,
        subscriptionSerial,
        cityCode,
        cityName,
        address,
        meterKind,
        meterModel,
        meterSerialNum,
        isSmart,
        phase,
        subscriptionKind,
        subscriptionType,
        lastReading,
        lastReadingDate,
        supportPhone,
        regionCode,
        readerName,
        posX,
        posY,
        hasTimeOfUse,
        isRenewable,
        timeReadings,
        hasIllegalNotification,
      ];
}
