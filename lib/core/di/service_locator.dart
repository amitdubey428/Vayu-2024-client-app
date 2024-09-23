import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:vayu_flutter_app/data/repositories/trip_repository.dart';
import 'package:vayu_flutter_app/data/repositories/user_repository.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/services/attachment_service.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/blocs/user/user_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External services
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerLazySingleton(() => FirebaseAuth.instance);

  // Register ApiService first
  getIt.registerLazySingleton(() => ApiService(
        dotenv.env['API_BASE_URL'] ?? '',
        getToken: () async => await getIt<AuthNotifier>().getRefreshedIdToken(),
      ));

  // Register UserRepository
  getIt.registerLazySingleton<UserRepository>(
      () => UserRepository(getIt<ApiService>()));

  // Register AuthNotifier
  getIt.registerLazySingleton<AuthNotifier>(() => AuthNotifier(
        getIt<FirebaseAuth>(),
        getIt<ApiService>(),
        getIt<UserRepository>(),
      ));

  // App services
  getIt.registerLazySingleton(() => TripRepository(getIt<ApiService>()));
  getIt.registerLazySingleton(() => TripService(getIt<TripRepository>()));
  getIt.registerLazySingleton(() => AttachmentService());

  // Register UserBloc
  getIt.registerFactory<UserBloc>(() => UserBloc());
}
