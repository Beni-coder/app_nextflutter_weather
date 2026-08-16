/// Météo actuelle d'une ville (entité de la couche domaine).
class CurrentWeather {
  const CurrentWeather({
    required this.cityName,
    required this.country,
    required this.description,
    required this.iconCode,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.observedAt,
  });

  final String cityName;
  final String? country;

  /// Description en français fournie par l'API (lang=fr).
  final String description;
  final String iconCode;

  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;

  /// Vitesse du vent en m/s.
  final double windSpeed;

  /// Pression atmosphérique en hPa.
  final int pressure;

  /// Date d'observation.
  final DateTime observedAt;
}

/// Prévision à un instant donné (pas de 3 heures).
class ForecastItem {
  const ForecastItem({
    required this.dateTime,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
  });

  final DateTime dateTime;
  final double temperature;
  final double feelsLike;
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
}

/// Prévisions sur plusieurs jours pour une ville.
class WeatherForecast {
  const WeatherForecast({
    required this.cityName,
    required this.country,
    required this.items,
  });

  final String cityName;
  final String? country;
  final List<ForecastItem> items;
}

/// Suggestion de ville renvoyée par l'API de géocodage.
class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.country,
    this.state,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String country;
  final String? state;
  final double latitude;
  final double longitude;
}
