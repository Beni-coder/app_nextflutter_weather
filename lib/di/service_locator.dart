import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/network/dio_client.dart';
import '../core/network/interceptors/auth_interceptor.dart';
import '../features/auth/data/datasources/auth_backend.dart';
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/weather/data/datasources/weather_local_data_source.dart';
import '../features/weather/data/datasources/weather_remote_data_source.dart';
import '../features/weather/data/repositories/weather_repository_impl.dart';
import '../features/weather/domain/repositories/weather_repository.dart';
import '../features/weather/presentation/controllers/favorites_controller.dart';
import '../features/weather/presentation/controllers/weather_controller.dart';

/// Conteneur d'injection de dépendances construit au démarrage :
/// boîtes Hive, Dio + intercepteurs, dépôts et contrôleurs.
class ServiceLocator {
  const ServiceLocator({
    required this.dio,
    required this.authRepository,
    required this.weatherRepository,
    required this.authController,
    required this.weatherController,
    required this.favoritesController,
  });

  final Dio dio;
  final AuthRepository authRepository;
  final WeatherRepository weatherRepository;
  final AuthController authController;
  final WeatherController weatherController;
  final FavoritesController favoritesController;

  /// Initialise toutes les dépendances de l'application.
  static Future<ServiceLocator> initialize() async {
    // ---------------------------------------------------------------------
    // Persistance locale (Hive)
    // ---------------------------------------------------------------------
    await Hive.initFlutter();
    final usersBox = await Hive.openBox<dynamic>(AppConstants.usersBoxName);
    final sessionBox =
        await Hive.openBox<dynamic>(AppConstants.sessionBoxName);
    final weatherBox =
        await Hive.openBox<dynamic>(AppConstants.weatherCacheBoxName);

    // ---------------------------------------------------------------------
    // Feature auth : backend JWT -> source distante -> dépôt
    // ---------------------------------------------------------------------
    final authBackend = AuthBackend(usersBox);
    final authRemote = AuthRemoteDataSource(authBackend);
    final authLocal = AuthLocalDataSource(sessionBox);
    final authRepository =
        AuthRepositoryImpl(remoteDataSource: authRemote, localDataSource: authLocal);

    // ---------------------------------------------------------------------
    // Réseau : Dio + intercepteurs (injection du jeton, refresh 401,
    // traduction des erreurs en français)
    // ---------------------------------------------------------------------
    final authInterceptor = AuthInterceptor(
      apiKey: AppConstants.openWeatherAppId,
      tokens: AuthTokenProvider(authRepository),
    );
    final dio = createWeatherDio(
      baseUrl: AppConstants.openWeatherBaseUrl,
      authInterceptor: authInterceptor,
    );

    // ---------------------------------------------------------------------
    // Feature weather : source distante + cache local -> dépôt
    // ---------------------------------------------------------------------
    final weatherRemote = WeatherRemoteDataSource(dio);
    final weatherLocal = WeatherLocalDataSource(weatherBox);
    final weatherRepository = WeatherRepositoryImpl(
      remoteDataSource: weatherRemote,
      localDataSource: weatherLocal,
    );

    // ---------------------------------------------------------------------
    // Contrôleurs (state management via provider)
    // ---------------------------------------------------------------------
    final authController = AuthController(authRepository);
    final weatherController = WeatherController(weatherRepository);
    final favoritesController = FavoritesController(weatherRepository);

    // Restauration de la session persistée (refresh token si nécessaire).
    authController.restoreSession();

    return ServiceLocator(
      dio: dio,
      authRepository: authRepository,
      weatherRepository: weatherRepository,
      authController: authController,
      weatherController: weatherController,
      favoritesController: favoritesController,
    );
  }
}
