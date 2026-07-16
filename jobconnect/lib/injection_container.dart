import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/dio_client.dart';
import 'core/theme/theme_controller.dart';
import 'data/datasources/auth_datasource.dart';
import 'data/datasources/company_datasource.dart';
import 'data/datasources/mastra_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'domain/usecases/auth/login_usecase.dart';
import 'domain/usecases/auth/register_usecase.dart';
import 'domain/usecases/auth/logout_usecase.dart';
import 'domain/usecases/auth/change_password_usecase.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/feed/applications_cubit.dart';
import 'presentation/blocs/profile/all_candidates/candidate_detail_cubit.dart';
import 'presentation/blocs/profile/company_profile/company_profil_cubit.dart';
import 'presentation/blocs/profile/dashboard/dashboard_cubit.dart';
import 'presentation/blocs/profile/all_candidates/all_candidates_cubit.dart';
import 'presentation/blocs/profile/offers/offers_cubit.dart';
import 'presentation/blocs/profile/offers/create_offer_cubit.dart';
import 'presentation/blocs/profile/offers/offer_detail_cubit.dart';
import 'presentation/blocs/profile/student_profile/student_profile_cubit.dart';
import 'presentation/blocs/messaging/messaging_cubit.dart';
import 'presentation/blocs/feed/feed_cubit.dart';
import 'presentation/blocs/feed/offer_detail_student_cubit.dart';
import 'presentation/blocs/feed/company_detail_cubit.dart';
import 'presentation/blocs/feed/success_cubit.dart';
import 'presentation/blocs/search/search_cubit.dart';
import 'presentation/blocs/notifications/notification_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Supabase client
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Dio client
  sl.registerLazySingleton(() => DioClient.instance);

  // Theme controller
  sl.registerLazySingleton(() => ThemeController());

  // ===== AUTH MODULE =====

  sl.registerLazySingleton<IMastraRemoteDataSource>(
    () => MastraRemoteDataSource(),
  );

  sl.registerLazySingleton<IAuthDataSource>(
    () => AuthDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));

  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      changePasswordUseCase: sl(),
      repository: sl(),
    ),
  );

  // ===== COMPANY MODULE =====

  sl.registerLazySingleton(() => CompanyDataSource());

  sl.registerFactory(
    () => CompanyProfileCubit(dataSource: sl()),
  );

  sl.registerFactory(
    () => DashboardCubit(),
  );

  sl.registerFactory(
    () => AllCandidatesCubit(),
  );

  sl.registerFactory(
    () => OffersCubit(),
  );

  sl.registerFactory(
    () => CreateOfferCubit(mastraRemoteDataSource: sl<IMastraRemoteDataSource>()),
  );

  sl.registerFactory(
    () => OfferDetailCubit(),
  );

  // ===== STUDENT MODULE =====

  sl.registerFactory(
    () => FeedCubit(),
  );

  sl.registerFactory(
    () => OfferDetailStudentCubit(),
  );

  sl.registerFactory(
    () => CompanyDetailCubit(),
  );

  sl.registerFactory(
    () => StudentProfileCubit(mastraRemoteDataSource: sl()),
  );
  // Candidate detail
sl.registerFactory(() => CandidateDetailCubit());

  sl.registerFactory(
    () => SuccessCubit(),
  );
  // Applications
sl.registerFactory(() => ApplicationsCubit());

  // ===== MESSAGING MODULE =====

  sl.registerFactory(
    () => MessagingCubit(mastraDataSource: sl()),
  );

  
// recherche...
sl.registerFactory(() => SearchCubit());

// Notifications
sl.registerFactory(() => NotificationCubit(sl()));
//agent de Matching
//sl.registerLazySingleton(() => MatchingService());
//sl.registerFactory(() => MatchingCubit(service: sl()));
}
