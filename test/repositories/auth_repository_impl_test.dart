import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:certif_weather_app/core/errors/app_exception.dart';
import 'package:certif_weather_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:certif_weather_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:certif_weather_app/features/auth/data/models/session_model.dart';
import 'package:certif_weather_app/features/auth/data/models/user_model.dart';
import 'package:certif_weather_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late AuthRepositoryImpl repository;

  final session = SessionModel(
    accessToken: 'header.payload.signature',
    refreshToken: 'refresh.token.value',
    accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    user: const UserModel(
      email: 'test@exemple.fr',
      name: 'Test Utilisateur',
    ),
  );

  setUpAll(() {
    registerFallbackValue(dummySession());
  });

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
    // Les méthodes renvoyant Future<void> doivent être stubbées pour
    // éviter les casts implicites null -> Future<void>.
    when(() => local.saveSession(any())).thenAnswer((_) async {});
    when(() => local.clearSession()).thenAnswer((_) async {});
  });

  group('AuthRepositoryImpl.login', () {
    test(
      'connexion réussie : la session est sauvegardée localement et '
      'l\'utilisateur est retourné',
      () async {
        // Arrange
        when(
          () => remote.login(email: 'test@exemple.fr', password: 'secret1'),
        ).thenAnswer((_) async => session);

        // Act
        final user = await repository.login(
          email: 'test@exemple.fr',
          password: 'secret1',
        );

        // Assert
        expect(user.email, 'test@exemple.fr');
        expect(user.name, 'Test Utilisateur');
        verify(() => local.saveSession(session)).called(1);
        verifyNoMoreInteractions(local);
      },
    );

    test(
      'mot de passe incorrect : AuthException propagée, rien n\'est sauvegardé',
      () async {
        // Arrange
        when(
          () => remote.login(email: 'test@exemple.fr', password: 'mauvais'),
        ).thenThrow(const AuthException('Mot de passe incorrect.'));

        // Act + Assert
        await expectLater(
          repository.login(email: 'test@exemple.fr', password: 'mauvais'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Mot de passe incorrect.',
            ),
          ),
        );
        verifyNever(() => local.saveSession(any()));
      },
    );
  });

  group('AuthRepositoryImpl.register', () {
    test(
      'inscription réussie : session sauvegardée et utilisateur retourné',
      () async {
        // Arrange
        when(
          () => remote.register(
            name: 'Test Utilisateur',
            email: 'test@exemple.fr',
            password: 'secret1',
          ),
        ).thenAnswer((_) async => session);

        // Act
        final user = await repository.register(
          name: 'Test Utilisateur',
          email: 'test@exemple.fr',
          password: 'secret1',
        );

        // Assert
        expect(user.email, 'test@exemple.fr');
        verify(() => local.saveSession(session)).called(1);
      },
    );
  });

  group('AuthRepositoryImpl.restoreSession', () {
    test(
      'jeton d\'accès valide : session restaurée sans refresh',
      () async {
        // Arrange
        when(() => local.readSession()).thenReturn(session);
        when(() => remote.decodeAccessToken(session.accessToken))
            .thenReturn({'sub': 'test@exemple.fr', 'typ': 'access'});

        // Act
        final user = await repository.restoreSession();

        // Assert
        expect(user.email, 'test@exemple.fr');
        verifyNever(() => remote.refresh(any()));
      },
    );

    test(
      'jeton d\'accès expiré : refresh token utilisé et nouvelle session '
      'sauvegardée',
      () async {
        // Arrange
        when(() => local.readSession()).thenReturn(session);
        when(() => remote.decodeAccessToken(session.accessToken))
            .thenReturn(null);
        when(() => remote.refresh(session.refreshToken))
            .thenAnswer((_) async => session);

        // Act
        final user = await repository.restoreSession();

        // Assert
        expect(user.email, 'test@exemple.fr');
        verify(() => remote.refresh(session.refreshToken)).called(1);
        verify(() => local.saveSession(session)).called(1);
      },
    );

    test(
      'aucune session locale : AuthException levée avec un message français',
      () async {
        // Arrange
        when(() => local.readSession()).thenReturn(null);

        // Act + Assert
        await expectLater(
          repository.restoreSession(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Aucune session enregistrée.',
            ),
          ),
        );
      },
    );
  });

  group('AuthRepositoryImpl.tryRefreshSession', () {
    test(
      'refresh réussi : retourne true et persiste la nouvelle session',
      () async {
        // Arrange
        when(() => local.readSession()).thenReturn(session);
        when(() => remote.refresh(session.refreshToken))
            .thenAnswer((_) async => session);

        // Act + Assert
        expect(await repository.tryRefreshSession(), isTrue);
        verify(() => local.saveSession(session)).called(1);
      },
    );

    test(
      'refresh refusé : session locale effacée et retourne false',
      () async {
        // Arrange
        when(() => local.readSession()).thenReturn(session);
        when(() => remote.refresh(session.refreshToken))
            .thenThrow(const AuthException('Session expirée.'));

        // Act + Assert
        expect(await repository.tryRefreshSession(), isFalse);
        verify(() => local.clearSession()).called(1);
      },
    );
  });

  test('logout : efface uniquement la session locale', () async {
    when(() => local.clearSession()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => local.clearSession()).called(1);
    verifyNoMoreInteractions(local);
  });
}
