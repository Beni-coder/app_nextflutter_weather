import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/sourced_data.dart';
import '../../domain/entities/weather_entities.dart';
import '../../domain/repositories/weather_repository.dart';

/// Contrôleur des favoris : recherche de villes via l'API de géocodage,
/// gestion de la liste des villes favorites et de leur météo en cache.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final WeatherRepository _repository;

  List<String> _favorites = <String>[];
  Map<String, CurrentWeather> _cachedWeather = <String, CurrentWeather>{};
  List<CitySuggestion> _suggestions = <CitySuggestion>[];
  bool _searching = false;
  String? _error;

  List<String> get favorites => List.unmodifiable(_favorites);
  Map<String, CurrentWeather> get cachedWeather =>
      Map.unmodifiable(_cachedWeather);
  List<CitySuggestion> get suggestions => List.unmodifiable(_suggestions);
  bool get searching => _searching;
  String? get error => _error;

  /// Charge les favoris persistés et leur météo en cache (hors-ligne ok).
  Future<void> load() async {
    try {
      _favorites = await _repository.getFavorites();
      final cached = <String, CurrentWeather>{};
      for (final city in _favorites) {
        final weather = _repository.cachedCurrentWeather(city);
        if (weather != null) {
          cached[city] = weather;
        }
      }
      _cachedWeather = cached;
    } on AppException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }

  /// Recherche des villes par nom (API REST /geo/1.0/direct).
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _suggestions = <CitySuggestion>[];
      notifyListeners();
      return;
    }

    _searching = true;
    _error = null;
    notifyListeners();

    try {
      _suggestions = await _repository.searchCities(trimmed);
    } on AppException catch (e) {
      _suggestions = <CitySuggestion>[];
      _error = e.message;
    }

    _searching = false;
    notifyListeners();
  }

  /// Efface les suggestions courantes (après ajout ou annulation).
  void clearSuggestions() {
    _suggestions = <CitySuggestion>[];
    notifyListeners();
  }

  /// Ajoute une ville aux favoris et préchauffe son cache météo.
  Future<void> addFavorite(CitySuggestion suggestion) async {
    await _repository.addFavorite(suggestion.name);
    _suggestions = <CitySuggestion>[];
    try {
      // Préchargement météo pour disposer d'un cache hors-ligne immédiat.
      final SourcedData<CurrentWeather> result =
          await _repository.getCurrentWeather(suggestion.name);
      _cachedWeather[suggestion.name] = result.data;
    } on AppException {
      // Le préchargement est optionnel : sans réseau, le favori reste ajouté.
    }
    await load();
  }

  /// Retire une ville des favoris.
  Future<void> removeFavorite(String city) async {
    await _repository.removeFavorite(city);
    await load();
  }
}
