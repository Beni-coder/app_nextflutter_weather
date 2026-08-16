import 'package:flutter/material.dart';

import 'app.dart';
import 'di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dependencies = await ServiceLocator.initialize();
    runApp(MeteoApp(dependencies: dependencies));
  } on Object catch (error) {
    // L'initialisation (Hive, réseau...) a échoué : plutôt qu'un écran
    // blanc, on affiche un message clair à l'utilisateur.
    runApp(_InitializationErrorApp(error: error));
  }
}

/// Écran d'erreur affiché lorsque l'initialisation de l'application
/// échoue (par exemple si une autre instance verrouille le cache local).
class _InitializationErrorApp extends StatelessWidget {
  const _InitializationErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Météo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Impossible de démarrer l\'application',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vérifiez qu\'une seule instance de l\'application est '
                  'ouverte, puis relancez-la.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
