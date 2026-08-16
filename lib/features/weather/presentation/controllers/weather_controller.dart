import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/sourced_data.dart';
import '../../domain/entities/weather_entities.dart';
import '../../domain/repositories/weather_repository.dart';

/// Contrôleur de la météo : ville sélectionnée, météo actuelle et
/// prévisions, gestion du chargement et des erreurs utilisateur.
class WeatherController extends ChangeNotifier {
  WeatherController(this._repository);

  final WeatherRepository _repository;

  String _city = '';
  SourcedData<CurrentWeather>? _current;
  SourcedData<WeatherForecast>? _forecast;
  bool _loading = false;
  String? _error;

  String get city => _city;
  SourcedData<CurrentWeather>? get current => _current;
  SourcedData<WeatherForecast>? get forecast => _forecast;
  bool get loading => _loading;
  String? get error => _error;

  bool get isOffline =>
      (_current?.fromCache ?? false) || (_forecast?.fromCache ?? false);

  /// Charge la ville précédemment sélectionnée puis les données météo.
  /// Ne s'exécute qu'une seule fois.
  Future<void> initializeIfNeeded() async {
    if (_city.isNotEmpty) return;
    _city = await _repository.getSelectedCity() ?? 'Paris';
    notifyListeners();
    await refresh();
  }

  /// Recharge la météo actuelle et les prévisions de la ville courante.
  Future<void> refresh() async {
    if (_city.isEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _current = await _repository.getCurrentWeather(_city);
    } on AppException catch (e) {
      // La donnée précédente reste affichée ; l'erreur est signalée à l'UI.
      _error = e.message;
    }

    try {
      _forecast = await _repository.getForecast(_city);
    } on AppException catch (e) {
      _error ??= e.message;
    }

    _loading = false;
    notifyListeners();
  }

  /// Change la ville consultée (persistée) puis recharge les données.
  Future<void> changeCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty || trimmed == _city) return;
    _city = trimmed;
    notifyListeners();
    await _repository.saveSelectedCity(trimmed);
    await refresh();
  }
}
