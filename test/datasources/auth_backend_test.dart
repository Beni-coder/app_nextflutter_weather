import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:certif_weather_app/core/errors/app_exception.dart';
import 'package:certif_weather_app/features/auth/data/datasources/auth_backend.dart';

void main() {
  late Box<dynamic> usersBox;
  late AuthBackend backend;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('auth_backend_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    usersBox = await Hive.openBox<dynamic>(
      'auth_backend_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    backend = AuthBackend(usersBox, accessTokenTtl: const Duration(minutes: 30));
  });

  tearDown(() async {
    await usersBox.deleteFromDisk();
  });

  test(
    'register puis login avec les mêmes identifiants réussissent',
    () async {
      final session = await backend.register(
        name: 'Alice Martin',
        email: 'alice@exemple.fr',
        password: 'motdepasse1',
      );

      expect(session.user.email, 'alice@exemple.fr');
      expect(session.accessToken, isNotEmpty);
      expect(session.refreshToken, isNotEmpty);

      final loginSession = await backend.login(
        email: 'alice@exemple.fr',
        password: 'motdepasse1',
      );
      expect(loginSession.user.name, 'Alice Martin');
    },
  );

  test(
    'login avec un mot de passe incorrect lève une AuthException en français',
    () async {
      await backend.register(
        name: 'Alice',
        email: 'alice@exemple.fr',
        password: 'motdepasse1',
      );

      await expectLater(
        backend.login(email: 'alice@exemple.fr', password: 'mauvais'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.message, 'message', 'Mot de passe incorrect.'),
        ),
      );
    },
  );

  test(
    'register avec un e-mail déjà utilisé lève une AuthException',
    () async {
      await backend.register(
        name: 'Alice',
        email: 'alice@exemple.fr',
        password: 'motdepasse1',
      );

      await expectLater(
        backend.register(
          name: 'Alice 2',
          email: 'alice@exemple.fr',
          password: 'motdepasse2',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Un compte existe déjà avec cet e-mail.',
          ),
        ),
      );
    },
  );

  test(
    'refresh token valide : une nouvelle session (rotation) est émise',
    () async {
      final session = await backend.register(
        name: 'Alice',
        email: 'alice@exemple.fr',
        password: 'motdepasse1',
      );

      final refreshed = await backend.refresh(session.refreshToken);

      expect(refreshed.user.email, 'alice@exemple.fr');
      expect(refreshed.accessToken, isNot(equals(session.accessToken)));
      expect(
        backend.decodeToken(refreshed.accessToken, expectedType: 'access'),
        isNotNull,
      );
    },
  );

  test(
    'jeton d\'accès expiré : decodeToken retourne null (refresh requis)',
    () async {
      final expiredBackend = AuthBackend(
        usersBox,
        accessTokenTtl: const Duration(seconds: -1),
      );
      final session = await expiredBackend.register(
        name: 'Bob',
        email: 'bob@exemple.fr',
        password: 'motdepasse1',
      );

      expect(
        backend.decodeToken(session.accessToken, expectedType: 'access'),
        isNull,
      );
    },
  );

  test(
    'jeton signé avec un type inattendu est rejeté',
    () async {
      final session = await backend.register(
        name: 'Bob',
        email: 'bob2@exemple.fr',
        password: 'motdepasse1',
      );

      // Un refresh token n'est pas un access token.
      expect(
        backend.decodeToken(session.refreshToken, expectedType: 'access'),
        isNull,
      );
    },
  );
}
