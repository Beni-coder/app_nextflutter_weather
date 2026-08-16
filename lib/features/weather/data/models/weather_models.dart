import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/weather_entities.dart';

/// Modèle de sérialisation de la météo actuelle (réponse
/// /data/2.5/weather de OpenWeatherMap + cache local).
class CurrentWeatherModel extends CurrentWeather {
  const CurrentWeatherModel({
    required super.cityName,
    required super.country,
    required super.description,
    required super.iconCode,
    required super.temperature,
    required super.feelsLike,
    required super.tempMin,
    required super.tempMax,
    required super.humidity,
    required super.windSpeed,
    required super.pressure,
    required super.observedAt,
  });

  /// Construit le modèle depuis la réponse JSON de l'API.
  factory CurrentWeatherModel.fromApi(Map<String, dynamic> json) {
    try {
      final weatherList = json['weather'] as List<dynamic>;
      final weather =
          (weatherList.isEmpty ? <String, dynamic>{} : weatherList.first)
              as Map<String, dynamic>;
      final main = json['main'] as Map<String, dynamic>;
      final wind = (json['wind'] as Map<String, dynamic>?) ?? const {};
      final sys = (json['sys'] as Map<String, dynamic>?) ?? const {};
      final dt = json['dt'] as int? ?? 0;

      return CurrentWeatherModel(
        cityName: (json['name'] as String?) ?? '',
        country: sys['country'] as String?,
        description: (weather['description'] as String?) ?? '',
        iconCode: (weather['icon'] as String?) ?? '01d',
        temperature: (main['temp'] as num).toDouble(),
        feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
        tempMin: (main['temp_min'] as num?)?.toDouble() ?? 0,
        tempMax: (main['temp_max'] as num?)?.toDouble() ?? 0,
        humidity: (main['humidity'] as num?)?.toInt() ?? 0,
        windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
        pressure: (main['pressure'] as num?)?.toInt() ?? 0,
        observedAt:
            DateTime.fromMillisecondsSinceEpoch(dt * 1000).toLocal(),
      );
    } on Exception catch (e) {
      throw ApiException(
        'Réponse météo inattendue du serveur : ${e.toString()}',
      );
    } on TypeError {
      throw const ApiException('Réponse météo illisible du serveur.');
    }
  }

  /// Construit le modèle depuis le cache local (format [toMap]).
  factory CurrentWeatherModel.fromCache(Map<String, dynamic> json) {
    return CurrentWeatherModel(
      cityName: json['city_name'] as String,
      country: json['country'] as String?,
      description: json['description'] as String,
      iconCode: json['icon_code'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      tempMin: (json['temp_min'] as num).toDouble(),
      tempMax: (json['temp_max'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      pressure: json['pressure'] as int,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['observed_at'] as num).toInt(),
      ),
    );
  }

  /// Sérialisation neutre utilisée pour le cache local.
  Map<String, dynamic> toMap() => {
        'city_name': cityName,
        'country': country,
        'description': description,
        'icon_code': iconCode,
        'temperature': temperature,
        'feels_like': feelsLike,
        'temp_min': tempMin,
        'temp_max': tempMax,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'pressure': pressure,
        'observed_at': observedAt.millisecondsSinceEpoch,
      };
}

/// Modèle de sérialisation d'une prévision (pas de 3 heures).
class ForecastItemModel extends ForecastItem {
  const ForecastItemModel({
    required super.dateTime,
    required super.temperature,
    required super.feelsLike,
    required super.description,
    required super.iconCode,
    required super.humidity,
    required super.windSpeed,
  });

  factory ForecastItemModel.fromApi(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List<dynamic>;
    final weather =
        (weatherList.isEmpty ? <String, dynamic>{} : weatherList.first)
            as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final wind = (json['wind'] as Map<String, dynamic>?) ?? const {};

    return ForecastItemModel(
      dateTime:
          DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000)
              .toLocal(),
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
      description: (weather['description'] as String?) ?? '',
      iconCode: (weather['icon'] as String?) ?? '01d',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
    );
  }

  factory ForecastItemModel.fromCache(Map<String, dynamic> json) =>
      ForecastItemModel(
        dateTime: DateTime.fromMillisecondsSinceEpoch(
          (json['date_time'] as num).toInt(),
        ),
        temperature: (json['temperature'] as num).toDouble(),
        feelsLike: (json['feels_like'] as num).toDouble(),
        description: json['description'] as String,
        iconCode: json['icon_code'] as String,
        humidity: json['humidity'] as int,
        windSpeed: (json['wind_speed'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'date_time': dateTime.millisecondsSinceEpoch,
        'temperature': temperature,
        'feels_like': feelsLike,
        'description': description,
        'icon_code': iconCode,
        'humidity': humidity,
        'wind_speed': windSpeed,
      };
}

/// Modèle de sérialisation des prévisions sur 5 jours (réponse
/// /data/2.5/forecast + cache local).
class WeatherForecastModel extends WeatherForecast {
  const WeatherForecastModel({
    required super.cityName,
    required super.country,
    required super.items,
  });

  factory WeatherForecastModel.fromApi(Map<String, dynamic> json) {
    try {
      final city = json['city'] as Map<String, dynamic>;
      final list = json['list'] as List<dynamic>;

      return WeatherForecastModel(
        cityName: (city['name'] as String?) ?? '',
        country: city['country'] as String?,
        items: list
            .map(
              (item) =>
                  ForecastItemModel.fromApi(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
    } on Exception {
      throw const ApiException('Réponse de prévisions illisible du serveur.');
    }
  }

  factory WeatherForecastModel.fromCache(Map<String, dynamic> json) {
    return WeatherForecastModel(
      cityName: json['city_name'] as String,
      country: json['country'] as String?,
      items: (json['items'] as List<dynamic>)
          .map(
            (item) => ForecastItemModel.fromCache(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() => {
        'city_name': cityName,
        'country': country,
        'items': items
            .map((item) => (item as ForecastItemModel).toMap())
            .toList(growable: false),
      };
}
