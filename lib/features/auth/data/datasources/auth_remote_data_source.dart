import '../models/session_model.dart';
import '../models/user_model.dart';
import 'auth_backend.dart';

/// Source de données distante d'authentification : seul point de contact
/// avec le backend JWT (simulé par [AuthBackend]).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._backend);

  final AuthBackend _backend;

  Future<SessionModel> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _backend.register(name: name, email: email, password: password);

  Future<SessionModel> login({
    required String email,
    required String password,
  }) =>
      _backend.login(email: email, password: password);

  Future<SessionModel> refresh(String refreshToken) =>
      _backend.refresh(refreshToken);

  Map<String, dynamic>? decodeAccessToken(String token) =>
      _backend.decodeToken(token, expectedType: 'access');
}

/// Session fictive utilisée par les tests unitaires.
SessionModel dummySession() => SessionModel(
      accessToken: 'a.b.c',
      refreshToken: 'r.s.t',
      accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const UserModel(email: 'test@exemple.fr', name: 'Test'),
    );
