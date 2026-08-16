import 'package:connectivity_plus/connectivity_plus.dart';

/// Service permettant de connaître l'état de la connexion réseau.
class NetworkInfo {
  NetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Retourne true si l'appareil dispose d'une connexion réseau.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
