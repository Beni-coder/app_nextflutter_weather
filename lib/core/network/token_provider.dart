/// Abstraction fournie à la couche réseau pour accéder aux jetons JWT
/// de l'utilisateur connecté, sans couplage avec la feature auth.
abstract class TokenProvider {
  /// Jeton d'accès courant, ou null si aucun utilisateur connecté.
  Future<String?> getAccessToken();

  /// Jeton de rafraîchissement courant, ou null.
  Future<String?> getRefreshToken();

  /// Tente de rafraîchir la session (access + refresh tokens).
  /// Retourne true en cas de succès.
  Future<bool> refreshTokens();
}
