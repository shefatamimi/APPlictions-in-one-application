/// # Injection Container
///
/// Dependency wiring for the platform and every hosted application.
///
/// Registration order follows the clean-architecture dependency rule:
/// 1. External (http.Client, FlutterSecureStorage, Connectivity)
/// 2. Core (SoapClient, NetworkInfo) — **shared by all applications**
/// 3. Platform shell (session storage, SSO repository, use cases, cubit)
/// 4. Modules, one clearly delimited block each
///
/// Adding an application means appending one block under "Modules" and one
/// entry to `AppRegistry` — nothing above it changes.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'core/network/network_info.dart';
import 'core/network/soap_client.dart';
import 'features/inquiry/data/datasources/inquiry_remote_datasource.dart';
import 'features/inquiry/data/repositories/inquiry_repository_impl.dart';
import 'features/inquiry/domain/repositories/inquiry_repository.dart';
import 'features/inquiry/domain/usecases/get_cities_usecase.dart';
import 'features/inquiry/domain/usecases/search_by_meter_usecase.dart';
import 'features/inquiry/domain/usecases/search_by_subscription_usecase.dart';
import 'features/inquiry/presentation/cubit/inquiry_cubit.dart';
import 'features/inspection_inquiry/data/datasources/inspection_inquiry_remote_datasource.dart';
import 'features/inspection_inquiry/data/repositories/inspection_inquiry_repository_impl.dart';
import 'features/inspection_inquiry/domain/repositories/inspection_inquiry_repository.dart';
import 'features/inspection_inquiry/domain/usecases/get_engineers_usecase.dart';
import 'features/inspection_inquiry/domain/usecases/get_helper_workshops_usecase.dart';
import 'features/inspection_inquiry/domain/usecases/get_operation_usecase.dart';
import 'features/inspection_inquiry/domain/usecases/insert_process_note_usecase.dart';
import 'features/inspection_inquiry/presentation/cubit/inspection_inquiry_cubit.dart';
import 'features/submission/data/datasources/submission_remote_datasource.dart';
import 'features/submission/data/repositories/submission_repository_impl.dart';
import 'features/submission/domain/repositories/submission_repository.dart';
import 'features/submission/domain/usecases/get_submissions_usecase.dart';
import 'features/submission/presentation/cubit/submission_cubit.dart';
import 'modules/meter_reading/data/coordinates_api.dart';
import 'platform/data/datasources/platform_auth_remote_datasource.dart';
import 'platform/data/datasources/platform_session_local_datasource.dart';
import 'platform/data/repositories/platform_auth_repository_impl.dart';
import 'platform/domain/repositories/platform_auth_repository.dart';
import 'platform/domain/usecases/restore_session_usecase.dart';
import 'platform/domain/usecases/sign_in_usecase.dart';
import 'platform/domain/usecases/sign_out_usecase.dart';
import 'platform/presentation/cubit/platform_auth_cubit.dart';

final sl = GetIt.instance;

/// Registers all dependencies. Call once before `runApp`.
void setupDependencies() {
  // ═══ External ══════════════════════════════════════════════════════════════

  sl.registerLazySingleton<http.Client>(() => http.Client());

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // ═══ Core — one API client for every application ═══════════════════════════

  sl.registerLazySingleton<SoapClient>(() => SoapClient(sl()));

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<Connectivity>()),
  );

  // ═══ Platform shell (single sign-on) ═══════════════════════════════════════

  sl.registerLazySingleton<PlatformAuthRemoteDataSource>(
    () => PlatformAuthRemoteDataSourceImpl(sl<SoapClient>()),
  );

  sl.registerLazySingleton<PlatformSessionLocalDataSource>(
    () => PlatformSessionLocalDataSourceImpl(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<PlatformAuthRepository>(
    () => PlatformAuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<SignInUseCase>(() => SignInUseCase(sl()));
  sl.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(sl()));
  sl.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(sl()),
  );

  // Singleton on purpose: the session must be identical everywhere.
  sl.registerLazySingleton<PlatformAuthCubit>(
    () => PlatformAuthCubit(
      signIn: sl(),
      signOut: sl(),
      restoreSession: sl(),
    ),
  );

  // ═══ Module: field inspection (app_id 20) ══════════════════════════════════

  sl.registerLazySingleton<InquiryRemoteDataSource>(
    () => InquiryRemoteDataSourceImpl(sl<SoapClient>()),
  );

  sl.registerLazySingleton<InspectionInquiryRemoteDataSource>(
    () => InspectionInquiryRemoteDataSourceImpl(sl<SoapClient>()),
  );

  sl.registerLazySingleton<SubmissionRemoteDataSource>(
    () => SubmissionRemoteDataSourceImpl(sl<SoapClient>()),
  );

  sl.registerLazySingleton<InquiryRepository>(
    () => InquiryRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<InspectionInquiryRepository>(
    () => InspectionInquiryRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SubmissionRepository>(
    () => SubmissionRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<GetCitiesUseCase>(() => GetCitiesUseCase(sl()));
  sl.registerLazySingleton<SearchByMeterUseCase>(
    () => SearchByMeterUseCase(sl()),
  );
  sl.registerLazySingleton<SearchBySubscriptionUseCase>(
    () => SearchBySubscriptionUseCase(sl()),
  );
  sl.registerLazySingleton<GetOperationUseCase>(
    () => GetOperationUseCase(sl()),
  );
  sl.registerLazySingleton<GetEngineersUseCase>(
    () => GetEngineersUseCase(sl()),
  );
  sl.registerLazySingleton<GetHelperWorkshopsUseCase>(
    () => GetHelperWorkshopsUseCase(sl()),
  );
  sl.registerLazySingleton<InsertProcessNoteUseCase>(
    () => InsertProcessNoteUseCase(sl()),
  );
  sl.registerLazySingleton<GetSubmissionsUseCase>(
    () => GetSubmissionsUseCase(sl()),
  );

  sl.registerFactory<InquiryCubit>(
    () => InquiryCubit(
      getCitiesUseCase: sl(),
      searchByMeterUseCase: sl(),
      searchBySubscriptionUseCase: sl(),
    ),
  );

  sl.registerFactory<InspectionInquiryCubit>(
    () => InspectionInquiryCubit(
      getOperationUseCase: sl(),
      getEngineersUseCase: sl(),
      getHelperWorkshopsUseCase: sl(),
      insertProcessNoteUseCase: sl(),
    ),
  );

  sl.registerFactory<SubmissionCubit>(() => SubmissionCubit(sl()));

  // ═══ Module: meter reading / coordinate capture (app_id 49) ════════════════

  sl.registerLazySingleton<CoordinatesApi>(
    () => CoordinatesApi(sl<SoapClient>()),
  );
}
