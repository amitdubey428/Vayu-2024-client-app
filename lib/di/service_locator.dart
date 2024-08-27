import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External services
  getIt.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance());
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => GoogleSignIn());
  getIt.registerLazySingleton(() => ApiService(
        dotenv.env['API_BASE_URL'] ?? '',
        getToken: () => getIt<AuthNotifier>().getRefreshedIdToken(),
      ));

  // App services
  getIt.registerLazySingleton(() => AuthNotifier(
        getIt<FirebaseAuth>(),
        getIt<SharedPreferences>(),
        getIt<GoogleSignIn>(),
        getIt<ApiService>(),
      ));
  // Register TripService
  getIt.registerLazySingleton(() => TripService());
}
