/// Hiérarchie d'exceptions métier portant des messages directement
/// exploitables par l'interface utilisateur (en français).
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Message compréhensible par l'utilisateur final.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Erreur liée au réseau (pas de connexion, timeout, DNS...).
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Erreur renvoyée par l'API (code HTTP invalide, payload inattendu...).
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});

  final int? statusCode;
}

/// Erreur liée au cache local (lecture/écriture impossible...).
class CacheException extends AppException {
  const CacheException(super.message);
}

/// Erreur liée à l'authentification (identifiants invalides,
/// session expirée, e-mail déjà utilisé...).
class AuthException extends AppException {
  const AuthException(super.message);
}
