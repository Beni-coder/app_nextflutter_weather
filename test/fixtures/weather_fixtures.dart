/// Jeux de données JSON représentant les réponses de l'API OpenWeatherMap,
/// utilisés par les tests unitaires.
const Map<String, dynamic> currentWeatherApiFixture = {
  'name': 'Paris',
  'sys': {'country': 'FR'},
  'weather': [
    {
      'main': 'Clouds',
      'description': 'couvert',
      'icon': '04d',
    }
  ],
  'main': {
    'temp': 21.3,
    'feels_like': 21.0,
    'temp_min': 19.0,
    'temp_max': 23.0,
    'humidity': 60,
    'pressure': 1015,
  },
  'wind': {'speed': 3.5},
  'dt': 1755300000,
};

const Map<String, dynamic> currentWeatherCacheFixture = {
  'city_name': 'Paris',
  'country': 'FR',
  'description': 'couvert',
  'icon_code': '04d',
  'temperature': 20.1,
  'feels_like': 19.8,
  'temp_min': 18.0,
  'temp_max': 22.0,
  'humidity': 65,
  'wind_speed': 2.4,
  'pressure': 1012,
  'observed_at': 1755300000000,
};

final Map<String, dynamic> forecastApiFixture = {
  'city': {'name': 'Paris', 'country': 'FR'},
  'cnt': 4,
  'list': [
    {
      'dt': 1755300000,
      'main': {'temp': 21.0, 'feels_like': 20.5, 'humidity': 55},
      'weather': [
        {'description': 'ciel dégagé', 'icon': '01d'}
      ],
      'wind': {'speed': 2.0},
    },
    {
      'dt': 1755310800,
      'main': {'temp': 22.4, 'feels_like': 22.0, 'humidity': 50},
      'weather': [
        {'description': 'peu nuageux', 'icon': '02d'}
      ],
      'wind': {'speed': 2.6},
    },
    {
      'dt': 1755386400,
      'main': {'temp': 19.8, 'feels_like': 19.0, 'humidity': 60},
      'weather': [
        {'description': 'pluie légère', 'icon': '10d'}
      ],
      'wind': {'speed': 4.1},
    },
    {
      'dt': 1755397200,
      'main': {'temp': 18.2, 'feels_like': 17.6, 'humidity': 70},
      'weather': [
        {'description': 'pluie modérée', 'icon': '10n'}
      ],
      'wind': {'speed': 5.0},
    },
  ],
};

final Map<String, dynamic> forecastCacheFixture = {
  'city_name': 'Paris',
  'country': 'FR',
  'items': [
    {
      'date_time': 1755300000000,
      'temperature': 21.0,
      'feels_like': 20.5,
      'description': 'ciel dégagé',
      'icon_code': '01d',
      'humidity': 55,
      'wind_speed': 2.0,
    },
    {
      'date_time': 1755310800000,
      'temperature': 22.4,
      'feels_like': 22.0,
      'description': 'peu nuageux',
      'icon_code': '02d',
      'humidity': 50,
      'wind_speed': 2.6,
    },
  ],
};
