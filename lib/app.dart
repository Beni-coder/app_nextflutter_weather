import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'di/service_locator.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/weather/presentation/screens/home_shell.dart';

/// Racine de l'application : thème, providers et porte d'entrée
/// de l'authentification (session restaurée -> accueil, sinon -> login).
class MeteoApp extends StatelessWidget {
  const MeteoApp({super.key, required this.dependencies});

  final ServiceLocator dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dependencies.authController),
        ChangeNotifierProvider.value(value: dependencies.weatherController),
        ChangeNotifierProvider.value(value: dependencies.favoritesController),
      ],
      child: MaterialApp(
        title: 'Météo App',
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr'),
        supportedLocales: const [
          Locale('fr'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: AnimatedBuilder(
          animation: dependencies.authController,
          builder: (context, _) {
            switch (dependencies.authController.status) {
              case AuthStatus.unknown:
                return const _SplashScreen();
              case AuthStatus.authenticated:
                return const HomeShell();
              case AuthStatus.unauthenticated:
                return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}

/// Écran affiché pendant la restauration de la session.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Météo App',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
