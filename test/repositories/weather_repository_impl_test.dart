import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:certif_weather_app/core/errors/app_exception.dart';
import 'package:certif_weather_app/features/weather/data/datasources/weather_local_data_source.dart';
import 'package:certif_weather_app/features/weather/data/datasources/weather_remote_data_source.dart';
import 'package:certif_weather_app/features/weather/data/repositories/weather_repository_impl.dart';

import '../fixtures/weather_fixtures.dart';

class MockWeatherRemoteDataSource extends Mock
    implements WeatherRemoteDataSource {}

class MockWeatherLocalDataSource extends Mock
    implements WeatherLocalDataSource {}

void main() {
  late MockWeatherRemoteDataSource remote;
  late MockWeatherLocalDataSource local;
  late WeatherRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    remote = MockWeatherRemoteDataSource();
    local = MockWeatherLocalDataSource();
    repository = WeatherRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });

  group('WeatherRepositoryImpl.getCurrentWeather', () {
    test(
      'succès API : données distantes retournées (fromCache = false) et '
      'mises en cache',
      () async {
        // Arrange
        when(() => remote.fetchCurrentWeather('Paris'))
            .thenAnswer((_) async => currentWeatherApiFixture);
        when(() => local.saveCurrentWeather('Paris', any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getCurrentWeather('Paris');

        // Assert
        expect(result.fromCache, isFalse);
        expect(result.data.cityName, 'Paris');
        expect(result.data.country, 'FR');
        expect(result.data.temperature, closeTo(21.3, 0.01));
        expect(result.data.description, 'couvert');
        verify(() => local.saveCurrentWeather('Paris', any())).called(1);
        verifyNever(() => local.readCurrentWeather(any()));
      },
    );

    test(
      'hors-ligne (échec réseau) : repli sur les données du cache '
      '(fromCache = true)',
      () async {
        // Arrange
        when(() => remote.fetchCurrentWeather('Paris')).thenThrow(
          const NetworkException(
            'Aucune connexion Internet. Vérifiez votre réseau puis réessayez.',
          ),
        );
        when(() => local.readCurrentWeather('Paris')).thenReturn({
          'fetched_at': 1755300000000,
          'payload': currentWeatherCacheFixture,
        });

        // Act
        final result = await repository.getCurrentWeather('Paris');

        // Assert
        expect(result.fromCache, isTrue);
        expect(result.data.cityName, 'Paris');
        expect(result.data.temperature, closeTo(20.1, 0.01));
        expect(result.fetchedAt, isNotNull);
      },
    );

    test(
      'hors-ligne sans cache disponible : NetworkException remontée avec '
      'un message utilisateur',
      () async {
        // Arrange
        when(() => remote.fetchCurrentWeather('Paris')).thenThrow(
          const NetworkException(
            'Aucune connexion Internet. Vérifiez votre réseau puis réessayez.',
          ),
        );
        when(() => local.readCurrentWeather('Paris')).thenReturn(null);

        // Act + Assert
        await expectLater(
          repository.getCurrentWeather('Paris'),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              contains('Aucune connexion Internet'),
            ),
          ),
        );
      },
    );
  });

  group('WeatherRepositoryImpl.getForecast', () {
    test(
      'succès API : prévisions retournées et mises en cache',
      () async {
        // Arrange
        when(() => remote.fetchForecast('Paris'))
            .thenAnswer((_) async => forecastApiFixture);
        when(() => local.saveForecast('Paris', any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getForecast('Paris');

        // Assert
        expect(result.fromCache, isFalse);
        expect(result.data.cityName, 'Paris');
        expect(result.data.items, hasLength(4));
        expect(result.data.items.first.temperature, closeTo(21.0, 0.01));
        verify(() => local.saveForecast('Paris', any())).called(1);
      },
    );

    test(
      'hors-ligne : prévisions lues depuis le cache local',
      () async {
        // Arrange
        when(() => remote.fetchForecast('Paris')).thenThrow(
          const NetworkException('Aucune connexion Internet.'),
        );
        when(() => local.readForecast('Paris')).thenReturn({
          'fetched_at': 1755300000000,
          'payload': forecastCacheFixture,
        });

        // Act
        final result = await repository.getForecast('Paris');

        // Assert
        expect(result.fromCache, isTrue);
        expect(result.data.items, hasLength(2));
        expect(result.data.items.last.description, 'peu nuageux');
      },
    );

    test(
      'ville introuvable (erreur API 404) : ApiException propagée avec '
      'message français',
      () async {
        // Arrange
        when(() => remote.fetchForecast('Nowhere')).thenThrow(
          const ApiException(
            'Ville introuvable. Vérifiez l\'orthographe puis réessayez.',
            statusCode: 404,
          ),
        );
        when(() => local.readForecast('Nowhere')).thenReturn(null);

        // Act + Assert
        await expectLater(
          repository.getForecast('Nowhere'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.message, 'message', contains('introuvable')),
          ),
        );
      },
    );
  });

  group('WeatherRepositoryImpl.searchCities', () {
    test('retourne les suggestions de villes formatées', () async {
      // Arrange
      when(() => remote.searchCities('lyo')).thenAnswer(
        (_) async => [
          {'name': 'Lyon', 'country': 'FR', 'lat': 45.75, 'lon': 4.85},
          {'name': 'Lyons', 'country': 'US', 'state': 'Georgia', 'lat': 32.2, 'lon': -82.5},
        ],
      );

      // Act
      final results = await repository.searchCities('lyo');

      // Assert
      expect(results, hasLength(2));
      expect(results.first.name, 'Lyon');
      expect(results.first.country, 'FR');
      expect(results.last.state, 'Georgia');
    });
  });

  group('WeatherRepositoryImpl.favoris', () {
    test(
      'addFavorite ajoute la ville une seule fois (idempotent)',
      () async {
        // Arrange : liste persistée simulée, mutée par saveFavorites.
        final persistedFavorites = <String>['Paris'];
        when(() => local.getFavorites())
            .thenAnswer((_) => List<String>.of(persistedFavorites));
        when(() => local.saveFavorites(any())).thenAnswer((invocation) {
          persistedFavorites
            ..clear()
            ..addAll(
              invocation.positionalArguments.first as List<String>,
            );
          return Future<void>.value();
        });

        // Act
        await repository.addFavorite('Lyon');
        await repository.addFavorite('Paris'); // déjà présent

        // Assert
        expect(persistedFavorites, equals(['Paris', 'Lyon']));
        verify(() => local.saveFavorites(['Paris', 'Lyon'])).called(1);
      },
    );

    test(
      'removeFavorite retire la ville de la liste persistée',
      () async {
        // Arrange
        when(() => local.getFavorites()).thenReturn(['Paris', 'Lyon']);
        when(() => local.saveFavorites(any())).thenAnswer((_) async {});

        // Act
        await repository.removeFavorite('Lyon');

        // Assert
        verify(() => local.saveFavorites(['Paris'])).called(1);
      },
    );
  });
}
