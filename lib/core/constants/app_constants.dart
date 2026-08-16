/// Constantes globales de l'application.
library;

import 'api_key.dart';

export 'api_key.dart';

class AppConstants {
  AppConstants._();

  /// Clé API OpenWeatherMap (définie dans api_key.dart, non commitée).
  static const String openWeatherAppId = openWeatherApiKey;

  /// URL de base de l'API OpenWeatherMap.
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org';

  /// Noms des boîtes Hive.
  static const String usersBoxName = 'auth_users_box';
  static const String sessionBoxName = 'auth_session_box';
  static const String weatherCacheBoxName = 'weather_cache_box';

  /// Durée de validité "fraîche" d'une donnée en cache (au-delà, elle est
  /// toujours affichable mais signalée comme potentielment obsolète).
  static const Duration cacheFreshness = Duration(minutes: 30);

  /// Ville sélectionnée par défaut au premier lancement.
  static const String defaultCity = 'Paris';
}
