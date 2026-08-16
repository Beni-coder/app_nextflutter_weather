import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/sourced_data.dart';
import '../../domain/entities/weather_entities.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_local_data_source.dart';
import '../datasources/weather_remote_data_source.dart';
import '../models/weather_models.dart';

/// Implémentation du dépôt météo :
/// - priorité au réseau (API OpenWeatherMap) ;
/// - chaque succès est mis en cache localement (Hive) ;
/// - en cas d'échec réseau, repli sur le cache (mode hors-ligne) ;
/// - sans cache disponible, l'erreur est remontée à l'UI en français.
class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({
    required WeatherRemoteDataSource remoteDataSource,
    required WeatherLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final WeatherRemoteDataSource _remote;
  final WeatherLocalDataSource _local;

  @override
  Future<SourcedData<CurrentWeather>> getCurrentWeather(String city) async {
    try {
      final apiData = await _remote.fetchCurrentWeather(city);
      final model = CurrentWeatherModel.fromApi(apiData);
      await _local.saveCurrentWeather(city, model.toMap());
      return SourcedData<CurrentWeather>(
        data: model,
        fromCache: false,
        fetchedAt: DateTime.now(),
      );
    } on Object catch (error) {
      return _fallbackToCache(
        city: city,
        error: error,
        readCache: _local.readCurrentWeather,
        build: (payload) => CurrentWeatherModel.fromCache(payload),
      );
    }
  }

  @override
  Future<SourcedData<WeatherForecast>> getForecast(String city) async {
    try {
      final apiData = await _remote.fetchForecast(city);
      final model = WeatherForecastModel.fromApi(apiData);
      await _local.saveForecast(city, model.toMap());
      return SourcedData<WeatherForecast>(
        data: model,
        fromCache: false,
        fetchedAt: DateTime.now(),
      );
    } on Object catch (error) {
      return _fallbackToCache(
        city: city,
        error: error,
        readCache: _local.readForecast,
        build: (payload) => WeatherForecastModel.fromCache(payload),
      );
    }
  }

  @override
  Future<List<CitySuggestion>> searchCities(String query) async {
    final results = await _remote.searchCities(query);
    return results
        .map(
          (json) => CitySuggestion(
            name: json['name'] as String? ?? '',
            country: json['country'] as String? ?? '',
            state: json['state'] as String?,
            latitude: (json['lat'] as num?)?.toDouble() ?? 0,
            longitude: (json['lon'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((city) => city.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  CurrentWeather? cachedCurrentWeather(String city) {
    final cached = _local.readCurrentWeather(city);
    if (cached == null) return null;
    final payload = cached['payload'];
    if (payload is! Map<String, dynamic>) return null;
    return CurrentWeatherModel.fromCache(payload);
  }

  @override
  Future<List<String>> getFavorites() async =>
      _local.getFavorites().toList(growable: false);

  @override
  Future<void> addFavorite(String city) async {
    final favorites = _local.getFavorites().toList();
    if (!favorites.contains(city)) {
      favorites.add(city);
      await _local.saveFavorites(favorites);
    }
  }

  @override
  Future<void> removeFavorite(String city) async {
    final favorites = _local.getFavorites()..remove(city);
    await _local.saveFavorites(favorites.toList(growable: false));
  }

  @override
  Future<String?> getSelectedCity() async => _local.getSelectedCity();

  @override
  Future<void> saveSelectedCity(String city) =>
      _local.saveSelectedCity(city);

  /// Stratégie de repli : si l'appel réseau échoue et qu'un cache existe,
  /// renvoyer les données cachées (fromCache = true). Sinon, propager
  /// l'erreur (message français).
  SourcedData<T> _fallbackToCache<T>({
    required String city,
    required Object error,
    required Map<String, dynamic>? Function(String) readCache,
    required T Function(Map<String, dynamic>) build,
  }) {
    final cached = readCache(city);
    final payload = cached?['payload'];
    if (cached != null && payload is Map<String, dynamic>) {
      final fetchedAtMs = cached['fetched_at'];
      return SourcedData<T>(
        data: build(payload),
        fromCache: true,
        fetchedAt: fetchedAtMs is int
            ? DateTime.fromMillisecondsSinceEpoch(fetchedAtMs)
            : null,
      );
    }
    throw error is AppException
        ? error
        : const NetworkException(
            'Aucune connexion Internet. Vérifiez votre réseau puis réessayez.',
          );
  }
}
