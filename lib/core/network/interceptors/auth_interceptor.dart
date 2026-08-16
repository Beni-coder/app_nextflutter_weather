import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../token_provider.dart';

/// Intercepteur chargé de :
/// 1. injecter la clé API OpenWeatherMap (paramètre APPID) dans chaque requête ;
/// 2. injecter le jeton JWT d'accès dans l'en-tête Authorization ;
/// 3. rafraîchir automatiquement les jetons et rejouer la requête
///    en cas de réponse 401 (jeton expiré).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required String apiKey,
    required TokenProvider tokens,
  })  : _appId = apiKey,
        _tokenProvider = tokens;

  final String _appId;
  final TokenProvider _tokenProvider;

  /// Instance Dio à laquelle l'intercepteur est rattaché, utilisée pour
  /// rejouer une requête après rafraîchissement du jeton.
  Dio? _dio;

  /// À appeler juste après avoir ajouté l'intercepteur à l'instance Dio.
  void attach(Dio dio) => _dio = dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.queryParameters['APPID'] = _appId;

    // OpenWeatherMap s'authentifie uniquement via le paramètre APPID.
    // L'en-tête Authorization n'est donc pas requis par l'API et, sur le
    // web, il transformerait la requête en requête "non simple" : le
    // navigateur émettrait une pré-requête CORS (OPTIONS) qu'OpenWeatherMap
    // ne traite pas, ce qui bloque l'appel. On ne l'injecte donc que sur
    // les plateformes natives (mobile, desktop).
    if (!kIsWeb) {
      final token = await _tokenProvider.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    final dio = _dio;

    if (status != 401 || alreadyRetried || dio == null) {
      handler.next(err);
      return;
    }

    // Tentative de rafraîchissement des jetons puis rejeu de la requête.
    final refreshed = await _tokenProvider.refreshTokens();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    try {
      err.requestOptions.extra['retried'] = true;
      final response = await dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
