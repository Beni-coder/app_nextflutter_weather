import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/token_provider.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/session_model.dart';

/// Implémentation du dépôt d'authentification : orchestre la source
/// distante (backend JWT) et la source locale (session persistée).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = await _remote.register(
      name: name,
      email: email,
      password: password,
    );
    await _persist(session);
    return session.user;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _remote.login(email: email, password: password);
    await _persist(session);
    return session.user;
  }

  @override
  Future<void> logout() => _local.clearSession();

  @override
  Future<AppUser> restoreSession() async {
    final session = _local.readSession();
    if (session == null) {
      throw const AuthException('Aucune session enregistrée.');
    }

    // Jeton d'accès encore valide : session restaurée telle quelle.
    if (_remote.decodeAccessToken(session.accessToken) != null) {
      return session.user;
    }

    // Jeton d'accès expiré : tentative de refresh token.
    try {
      final refreshed = await _remote.refresh(session.refreshToken);
      await _persist(refreshed);
      return refreshed.user;
    } on AuthException {
      await _local.clearSession();
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() async =>
      _local.readSession()?.accessToken;

  @override
  Future<String?> getRefreshToken() async =>
      _local.readSession()?.refreshToken;

  @override
  Future<bool> tryRefreshSession() async {
    final session = _local.readSession();
    if (session == null) return false;
    try {
      final refreshed = await _remote.refresh(session.refreshToken);
      await _persist(refreshed);
      return true;
    } on AppException {
      await _local.clearSession();
      return false;
    }
  }

  Future<void> _persist(SessionModel session) =>
      _local.saveSession(session);
}

/// Adaptateur exposant le dépôt d'authentification à la couche réseau
/// (injection du jeton + refresh sur 401) via l'abstraction [TokenProvider].
class AuthTokenProvider implements TokenProvider {
  AuthTokenProvider(this._repository);

  final AuthRepository _repository;

  @override
  Future<String?> getAccessToken() => _repository.getAccessToken();

  @override
  Future<String?> getRefreshToken() => _repository.getRefreshToken();

  @override
  Future<bool> refreshTokens() => _repository.tryRefreshSession();
}
