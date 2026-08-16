import '../../../../core/utils/sourced_data.dart';
import '../entities/weather_entities.dart';

/// Contrat du dépôt météo (couche domaine).
abstract class WeatherRepository {
  /// Météo actuelle d'une ville. En cas d'échec réseau, bascule sur le
  /// cache local (mode hors-ligne) si disponible.
  Future<SourcedData<CurrentWeather>> getCurrentWeather(String city);

  /// Prévisions sur 5 jours d'une ville, avec repli sur le cache.
  Future<SourcedData<WeatherForecast>> getForecast(String city);

  /// Recherche de villes par nom (API de géocodage OpenWeatherMap).
  Future<List<CitySuggestion>> searchCities(String query);

  /// Météo actuelle en cache pour une ville, sans appel réseau.
  CurrentWeather? cachedCurrentWeather(String city);

  /// Liste des villes favorites persistées.
  Future<List<String>> getFavorites();

  /// Ajoute une ville aux favoris (idempotent).
  Future<void> addFavorite(String city);

  /// Retire une ville des favoris.
  Future<void> removeFavorite(String city);

  /// Dernière ville sélectionnée par l'utilisateur.
  Future<String?> getSelectedCity();

  /// Persiste la ville sélectionnée.
  Future<void> saveSelectedCity(String city);
}
