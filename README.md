# Météo App — Application Flutter connectée à OpenWeatherMap

Application météo complète en français, connectée à l'API REST publique
OpenWeatherMap, avec authentification JWT, cache local Hive, mode hors-ligne
et gestion d'erreurs réseau.

## Fonctionnalités

- **Authentification complète** : inscription, connexion, déconnexion et
  restauration de session via des jetons JWT (access token + refresh token
  avec rotation).
- **Écran Aujourd'hui** : météo actuelle de la ville sélectionnée
  (température, ressenti, min/max, humidité, vent, pression), recherche de
  ville.
- **Écran Prévisions** : prévisions sur 5 jours (pas de 3 heures)
  regroupées par journée, détail par pas horaire dépliable.
- **Écran Favoris** : recherche de villes via l'API de géocodage
  OpenWeatherMap, gestion d'une liste de villes favorites avec leur météo.
- **Écran Profil** : informations de l'utilisateur connecté et déconnexion.
- **Mode hors-ligne** : les données météo sont mises en cache localement
  (Hive) à chaque succès ; en cas de perte de réseau, l'application affiche
  les données du cache avec un bandeau explicatif daté.
- **Gestion d'erreurs réseau** : toutes les erreurs (absence de connexion,
  ville introuvable, quota API dépassé, serveur indisponible, identifiants
  invalides...) sont traduites en messages clairs en français et affichées
  à l'utilisateur.

## API utilisée

L'API publique [OpenWeatherMap](https://openweathermap.org/api), appelée via
`https://api.openweathermap.org` :

| Endpoint | Usage |
| --- | --- |
| `GET /data/2.5/weather` | Météo actuelle d'une ville (`units=metric`, `lang=fr`) |
| `GET /data/2.5/forecast` | Prévisions sur 5 jours |
| `GET /geo/1.0/direct` | Recherche de villes (géocodage) |

La clé API est injectée automatiquement par un intercepteur Dio
(paramètre `APPID`), en même temps que le jeton JWT.

### À propos de l'authentification

OpenWeatherMap n'exposant aucune API d'authentification, l'application
embarque un **backend d'authentification JWT simulé** (`AuthBackend`) qui
reproduit fidèlement le comportement d'un serveur REST dédié : comptes
persistés (mots de passe salés et hachés en SHA-256), jetons JWT signés
HMAC-SHA256 avec expiration, refresh token avec rotation. Ce composant vit
dans la couche `data` et n'est consommé que par la source de données
distante, exactement comme un vrai serveur : le remplacer par une API réelle
ne demande de modifier aucun autre étage.

## Architecture

Architecture **Feature-First avec séparation Clean par feature** : chaque
feature (`auth`, `weather`) est découpée en trois couches
(`data` / `domain` / `presentation`), et le code transverse vit dans `core`.
La gestion d'état est assurée par `provider` (ChangeNotifier), et
l'injection de dépendances par un localisateur de services instancié au
démarrage.

```
lib/
├── main.dart                     # Point d'entrée (init Hive + DI)
├── app.dart                      # MaterialApp, thème, garde d'authentification
├── di/
│   └── service_locator.dart      # Assemblage des dépendances
└── core/                         # Code transverse
    ├── constants/                # Clé API, URLs, noms de boîtes Hive
    ├── errors/                   # Hiérarchie AppException (messages FR)
    ├── network/
    │   ├── dio_client.dart       # Instance Dio configurée
    │   ├── interceptors/
    │   │   ├── auth_interceptor.dart    # APPID + Bearer + refresh 401 + retry
    │   │   └── error_interceptor.dart   # DioException -> AppException (FR)
    │   ├── network_info.dart     # État de la connexion (connectivity_plus)
    │   └── token_provider.dart   # Abstraction des jetons pour la couche réseau
    ├── presentation/widgets/     # Bandeau hors-ligne, vue d'erreur
    └── utils/                    # SourcedData (provenance des données)

lib/features/auth/
├── domain/
│   ├── entities/                 # AppUser
│   └── repositories/             # Contrat AuthRepository
├── data/
│   ├── datasources/              # Backend JWT, sources distante et locale
│   ├── models/                   # UserModel, SessionModel
│   └── repositories/             # AuthRepositoryImpl + AuthTokenProvider
└── presentation/
    ├── controllers/              # AuthController (ChangeNotifier)
    └── screens/                  # Connexion, Inscription, Profil

lib/features/weather/
├── domain/
│   ├── entities/                 # CurrentWeather, Forecast, CitySuggestion
│   └── repositories/             # Contrat WeatherRepository
├── data/
│   ├── datasources/              # Source distante (Dio) + cache (Hive)
│   ├── models/                   # Modèles de sérialisation
│   └── repositories/             # WeatherRepositoryImpl (repli cache)
└── presentation/
    ├── controllers/              # WeatherController, FavoritesController
    ├── screens/                  # Aujourd'hui, Prévisions, Favoris, Shell
    └── widgets/                  # Carte météo, tuile journée, icône
```

### Flux de données (repository pattern)

1. La **présentation** appelle un **contrôleur** (ChangeNotifier).
2. Le contrôleur appelle un **dépôt** (contrat défini en `domain`,
   implémenté en `data`).
3. Le dépôt interroge la **source distante** (Dio + intercepteurs) ;
   en cas de succès il **met à jour le cache local** (Hive) et renvoie la
   donnée (`fromCache = false`).
4. En cas d'échec réseau, le dépôt **lit le cache** et renvoie la donnée
   (`fromCache = true`) ; sans cache, une `AppException` avec un message
   français remonte jusqu'à l'UI.

### Sécurité des requêtes

- `AuthInterceptor` injecte la clé API (`APPID`) et l'en-tête
  `Authorization: Bearer <JWT>` sur chaque requête, puis, sur réponse 401,
  rafraîchit automatiquement les jetons et rejoue la requête une fois.
  Sur le **web**, l'en-tête `Authorization` n'est pas envoyé : il rendrait
  la requête « non simple » et déclencherait une pré-requête CORS
  (OPTIONS) qu'OpenWeatherMap ne traite pas. L'API s'authentifiant
  uniquement via `APPID`, l'en-tête est inutile dans tous les cas et
  n'est injecté que sur les plateformes natives.
- À l'ouverture de l'application, la session persistée est restaurée : si
  l'access token (30 min) est expiré, le refresh token (14 jours) est
  utilisé pour en obtenir un nouveau.

## Configuration du projet

### Prérequis

- Flutter 3.x stable (testé avec 3.44.6 / Dart 3.12)
- Une connexion Internet (API OpenWeatherMap)

### Installation

```bash
# 1. Cloner le dépôt
git clone <url-du-repo>
cd certif_weather_app

# 2. Configurer la clé API OpenWeatherMap
#    (copier le gabarit puis renseigner votre clé personnelle,
#     obtenue gratuitement sur https://openweathermap.org/api)
cp lib/core/constants/api_key.example.dart lib/core/constants/api_key.dart

# 3. Installer les dépendances
flutter pub get

# 4. Lancer l'application
flutter run
```

La clé API vit dans `lib/core/constants/api_key.dart`, fichier **exclu du
dépôt** (voir `.gitignore`) pour éviter de publier un secret en clair : le
gabarit committé `api_key.example.dart` documente la manipulation. Le reste
de l'application la lit via `lib/core/constants/app_constants.dart`
(`openWeatherAppId`).

Aucune configuration supplémentaire n'est nécessaire : au premier lancement,
créez un compte depuis l'écran de connexion (bouton « Créer un compte »).

### Tests

```bash
flutter test
```

Le suite couvre notamment la couche repository (contrats, repli sur le
cache, messages d'erreur), le backend JWT et les écrans d'authentification :

- `test/repositories/auth_repository_impl_test.dart` — 8 tests sur le dépôt
  d'authentification (login/register/logout, restauration et refresh de
  session).
- `test/repositories/weather_repository_impl_test.dart` — 9 tests sur le
  dépôt météo (succès API + mise en cache, repli hors-ligne sur le cache,
  erreurs réseau et 404, favoris).
- `test/datasources/auth_backend_test.dart` — 6 tests sur l'émission et la
  validation des jetons JWT.
- `test/widgets/login_screen_test.dart` — tests widget de l'écran de
  connexion.

### Analyse statique

```bash
flutter analyze
```

## Principales dépendances

| Paquet | Rôle |
| --- | --- |
| `dio` | Appels réseau (intercepteurs, timeouts) |
| `provider` | Gestion d'état (ChangeNotifier) |
| `hive` / `hive_flutter` | Cache local et persistance (session, favoris, météo) |
| `connectivity_plus` | Détection de l'état du réseau |
| `crypto` | Signature JWT (HMAC-SHA256) et hachage des mots de passe |
| `intl` | Formatage des dates et nombres en français |
| `mocktail` | Doublures de tests |

## Structure des fonctionnalités obligatoires

| Exigence | Implémentation |
| --- | --- |
| Authentification JWT | `features/auth` — backend JWT simulé, session persistée, refresh token avec rotation |
| 3+ écrans de données REST | Aujourd'hui (`/data/2.5/weather`), Prévisions (`/data/2.5/forecast`), Favoris (`/geo/1.0/direct`) |
| Cache local | Hive : météo par ville (payload + date), favoris, session |
| Mode hors-ligne | Repli automatique du repository sur le cache + bandeau daté |
| Gestion d'erreurs réseau | `ErrorInterceptor` -> `AppException` en français -> UI |
| Architecture clean / feature-first | `core` + `features/{auth,weather}/{data,domain,presentation}` |
| Repository pattern | Contrats en `domain/repositories`, implémentations en `data/repositories` |
| Dio | `core/network/dio_client.dart` |
| Intercepteur d'injection du jeton | `core/network/interceptors/auth_interceptor.dart` |
| Refresh token | Rotation + retry 401 automatique + restauration au démarrage |
| Tests repository (3 minimum) | 17 tests sur les deux dépôts |
