import '../entities/app_user.dart';

/// Contrat du dépôt d'authentification (couche domaine).
abstract class AuthRepository {
  /// Inscrit un nouvel utilisateur et ouvre sa session.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  /// Connecte un utilisateur existant.
  Future<AppUser> login({
    required String email,
    required String password,
  });

  /// Déconnecte l'utilisateur courant (suppression de la session locale).
  Future<void> logout();

  /// Restaure la session persistée : si le jeton d'accès est expiré,
  /// tente un refresh token avant de renvoyer l'utilisateur.
  Future<AppUser> restoreSession();

  /// Jeton d'accès courant (pour l'intercepteur HTTP), ou null.
  Future<String?> getAccessToken();

  /// Jeton de rafraîchissement courant, ou null.
  Future<String?> getRefreshToken();

  /// Tente de rafraîchir la session à partir du refresh token.
  /// Retourne true en cas de succès.
  Future<bool> tryRefreshSession();
}
