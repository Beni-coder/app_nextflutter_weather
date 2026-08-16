import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Construit l'instance Dio unique de l'application, configurée pour
/// l'API OpenWeatherMap avec ses intercepteurs (auth + erreurs).
Dio createWeatherDio({
  required String baseUrl,
  required AuthInterceptor authInterceptor,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    authInterceptor,
    ErrorInterceptor(),
    if (kDebugMode)
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        responseHeader: false,
      ),
  ]);

  // Nécessaire pour permettre à l'intercepteur de rejouer une requête
  // après un rafraîchissement de jeton.
  authInterceptor.attach(dio);

  return dio;
}
