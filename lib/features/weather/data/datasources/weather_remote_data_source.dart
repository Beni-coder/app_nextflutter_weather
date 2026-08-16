import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';

/// Source de données distante pour la météo : encapsule tous les appels
/// HTTP vers l'API OpenWeatherMap via Dio (baseUrl + intercepteurs).
class WeatherRemoteDataSource {
  WeatherRemoteDataSource(this._dio);

  final Dio _dio;

  /// Météo actuelle d'une ville (units=metric, descriptions en français).
  Future<Map<String, dynamic>> fetchCurrentWeather(String city) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/data/2.5/weather',
        queryParameters: {
          'q': city,
          'units': 'metric',
          'lang': 'fr',
        },
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// Prévisions sur 5 jours par pas de 3 heures.
  Future<Map<String, dynamic>> fetchForecast(String city) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/data/2.5/forecast',
        queryParameters: {
          'q': city,
          'units': 'metric',
          'lang': 'fr',
        },
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// Recherche de villes (API de géocodage /geo/1.0/direct).
  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/geo/1.0/direct',
        queryParameters: {
          'q': query,
          'limit': 6,
        },
      );
      final data = response.data ?? const <dynamic>[];
      return data
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  /// L'intercepteur d'erreurs a déjà traduit l'erreur en AppException :
  /// on la propage telle quelle, sinon on renvoie une erreur réseau.
  Object _toAppException(DioException e) {
    final error = e.error;
    if (error is AppException) return error;
    return const NetworkException(
      'Aucune connexion Internet. Vérifiez votre réseau puis réessayez.',
    );
  }
}
