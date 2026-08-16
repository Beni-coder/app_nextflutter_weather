import 'package:dio/dio.dart';

import '../../errors/app_exception.dart';

/// Intercepteur qui transforme les erreurs brutes de Dio en exceptions
/// métier [AppException] portant des messages en français destinés
/// directement à l'utilisateur.
class ErrorInterceptor extends Interceptor {
  static const String noInternetMessage =
      'Aucune connexion Internet. Vérifiez votre réseau puis réessayez.';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Une AppException est peut-être déjà portée par l'erreur.
    if (err.error is AppException) {
      handler.next(err);
      return;
    }
    handler.next(_translate(err));
  }

  DioException _translate(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return err.copyWith(
          error: const NetworkException(noInternetMessage),
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        return err.copyWith(
          error: _fromResponse(err.response),
        );

      case DioExceptionType.cancel:
        return err.copyWith(
          error: const NetworkException('La requête a été annulée.'),
        );

      case DioExceptionType.unknown:
        return err.copyWith(
          error: const NetworkException(
            'Erreur réseau inattendue. Vérifiez votre connexion et réessayez.',
          ),
        );
    }
  }

  AppException _fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;
    final apiMessage =
        data is Map<String, dynamic> ? data['message']?.toString() : null;

    // Messages spécifiques renvoyés par OpenWeatherMap.
    if (apiMessage == 'city not found') {
      return ApiException(
        'Ville introuvable. Vérifiez l\'orthographe puis réessayez.',
        statusCode: statusCode,
      );
    }
    if (apiMessage == 'Nothing to geocode') {
      return ApiException(
        'Aucune ville ne correspond à cette recherche.',
        statusCode: statusCode,
      );
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          'Requête invalide. Vérifiez les informations saisies.',
          statusCode: statusCode,
        );
      case 401:
        return ApiException(
          'Authentification refusée. Votre session a peut-être expiré.',
          statusCode: statusCode,
        );
      case 403:
        return ApiException(
          'Accès refusé à l\'API météo. Vérifiez la clé API.',
          statusCode: statusCode,
        );
      case 404:
        return ApiException(
          'Ressource introuvable. Vérifiez l\'orthographe de la ville.',
          statusCode: statusCode,
        );
      case 429:
        return ApiException(
          'Limite d\'appels à l\'API atteinte. Réessayez dans quelques minutes.',
          statusCode: statusCode,
        );
      default:
        if (statusCode >= 500) {
          return ApiException(
            'Le service météo est momentanément indisponible. Réessayez plus tard.',
            statusCode: statusCode,
          );
        }
        return ApiException(
          'Une erreur est survenue lors de l\'appel au service météo.',
          statusCode: statusCode,
        );
    }
  }
}
