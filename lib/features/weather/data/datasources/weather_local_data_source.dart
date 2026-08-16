import 'package:hive/hive.dart';

import '../../../../core/errors/app_exception.dart';

/// Source de données locale de la météo : cache Hive des réponses API
/// (météo actuelle + prévisions par ville) et préférences (favoris,
/// ville sélectionnée).
class WeatherLocalDataSource {
  WeatherLocalDataSource(this._box);

  static const String _favoritesKey = 'favorites';
  static const String _selectedCityKey = 'selected_city';

  final Box<dynamic> _box;

  // ---------------------------------------------------------------------
  // Cache météo actuelle
  // ---------------------------------------------------------------------

  Future<void> saveCurrentWeather(String city, Map<String, dynamic> payload) =>
      _box.put('current:$city', _wrapForCache(payload));

  Map<String, dynamic>? readCurrentWeather(String city) =>
      _readCache('current:$city');

  // ---------------------------------------------------------------------
  // Cache prévisions
  // ---------------------------------------------------------------------

  Future<void> saveForecast(String city, Map<String, dynamic> payload) =>
      _box.put('forecast:$city', _wrapForCache(payload));

  Map<String, dynamic>? readForecast(String city) => _readCache('forecast:$city');

  // ---------------------------------------------------------------------
  // Favoris et ville sélectionnée
  // ---------------------------------------------------------------------

  List<String> getFavorites() {
    final raw = _box.get(_favoritesKey);
    if (raw is List) {
      return raw.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  Future<void> saveFavorites(List<String> cities) =>
      _box.put(_favoritesKey, cities);

  String? getSelectedCity() {
    final raw = _box.get(_selectedCityKey);
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  Future<void> saveSelectedCity(String city) =>
      _box.put(_selectedCityKey, city);

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Map<String, dynamic> _wrapForCache(Map<String, dynamic> payload) => {
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
        'payload': payload,
      };

  Map<String, dynamic>? _readCache(String key) {
    try {
      final raw = _box.get(key);
      if (raw is! Map) return null;
      return <String, dynamic>{
        'fetched_at': raw['fetched_at'],
        'payload': raw['payload'],
      };
    } on Exception {
      throw const CacheException('Impossible de lire le cache local.');
    }
  }
}
