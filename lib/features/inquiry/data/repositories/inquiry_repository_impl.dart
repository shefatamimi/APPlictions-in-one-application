/// # InquiryRepositoryImpl
///
/// Concrete implementation of [InquiryRepository] that orchestrates the
/// multi-step SOAP lookup flow and maps exceptions to typed [Failure] values.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/customer_info_entity.dart';
import '../../domain/repositories/inquiry_repository.dart';
import '../datasources/inquiry_remote_datasource.dart';
import '../models/customer_info_model.dart';

class InquiryRepositoryImpl implements InquiryRepository {
  final InquiryRemoteDataSource _remote;

  const InquiryRepositoryImpl(this._remote);

  // ── searchByMeter ──────────────────────────────────────────────────────────

  /// **SOAP chain**: DataType:31 → DataType:13 → DataType:18
  ///
  /// Fetches primary meter info, then merges extra subscription fields and
  /// the illegal-notification flag before returning.
  @override
  Future<Either<Failure, CustomerInfoEntity>> searchByMeter(
    String meterNum,
  ) async {
    try {
      // Step 1: fetch primary meter info
      CustomerInfoModel model = await _remote.searchByMeter(meterNum);

      // Step 2: merge extra subscription info (type, reading, date)
      final sub10 = model.formattedSubscription;
      try {
        final extraXml = await _remote.fetchExtraInfo(sub10);
        model = model.withExtraInfo(extraXml);
      } catch (_) {
        // Non-fatal — continue without extra info
      }

      // Step 3: check for illegal notification
      try {
        final notifXml = await _remote.checkIllegalNotification(sub10);
        final hasNotif = CustomerInfoModel.hasNotificationFromXml(notifXml);
        model = model.withNotification(hasNotif) as CustomerInfoModel;
      } catch (_) {
        // Non-fatal
      }

      return Right(model);
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  // ── searchBySubscription ───────────────────────────────────────────────────

  /// **SOAP chain**: DataType:12 (resolve meter) → full [searchByMeter] chain.
  @override
  Future<Either<Failure, CustomerInfoEntity>> searchBySubscription(
    String cityCode,
    String subSerial,
  ) async {
    try {
      final meterNum =
          await _remote.resolveMeterFromSubscription(cityCode, subSerial);
      return searchByMeter(meterNum);
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  // ── searchBy10Digit ────────────────────────────────────────────────────────

  /// Splits a 10-digit subscription into 3+7 and delegates to
  /// [searchBySubscription].
  @override
  Future<Either<Failure, CustomerInfoEntity>> searchBy10Digit(
    String subscription10,
  ) async {
    final s = subscription10.trim();
    if (s.length < 10) {
      return Left(ServerFailure('رقم الإشتراك يجب أن يكون 10 خانات'));
    }
    return searchBySubscription(s.substring(0, 3), s.substring(3));
  }

  // ── getCities ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CityEntity>>> getCities() async {
    try {
      final cities = await _remote.getCities();
      return Right(cities);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
