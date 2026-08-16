import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:certif_weather_app/core/errors/app_exception.dart';
import 'package:certif_weather_app/features/auth/domain/entities/app_user.dart';
import 'package:certif_weather_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:certif_weather_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:certif_weather_app/features/auth/presentation/screens/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = MockAuthRepository();
    controller = AuthController(repository);
  });

  testWidgets(
    'l\'écran de connexion affiche le formulaire complet en français',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: controller,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.text('Météo App'), findsOneWidget);
      expect(find.text('Adresse e-mail'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Pas encore de compte ? Créer un compte'), findsOneWidget);
    },
  );

  testWidgets(
    'soumettre un formulaire vide affiche les messages de validation',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: controller,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      expect(
        find.text('Veuillez saisir votre adresse e-mail.'),
        findsOneWidget,
      );
      expect(
        find.text('Veuillez saisir votre mot de passe.'),
        findsOneWidget,
      );
      verifyNever(
        () => repository.login(email: any(named: 'email'), password: any(named: 'password')),
      );
    },
  );

  testWidgets(
    'une erreur de connexion est affichée à l\'utilisateur',
    (tester) async {
      when(() => repository.login(
            email: 'test@exemple.fr',
            password: 'mauvais',
          )).thenThrow(const AuthException('Mot de passe incorrect.'));

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: controller,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@exemple.fr',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'mauvais',
      );
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      expect(find.text('Mot de passe incorrect.'), findsOneWidget);
    },
  );

  test(
    'login réussi : le contrôleur passe en état authentifié',
    () async {
      when(() => repository.login(
            email: 'test@exemple.fr',
            password: 'secret1',
          )).thenAnswer(
        (_) async => const AppUser(email: 'test@exemple.fr', name: 'Test'),
      );

      final success = await controller.login(
        email: 'test@exemple.fr',
        password: 'secret1',
      );

      expect(success, isTrue);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.user?.email, 'test@exemple.fr');
      expect(controller.error, isNull);
    },
  );
}
