import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/string_utils.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/weather_controller.dart';
import '../../domain/entities/weather_entities.dart';

/// Écran "Favoris" : recherche de villes via l'API de géocodage,
/// gestion de la liste des villes favorites.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onCitySelected});

  /// Callback appelé lorsqu'un favori est sélectionné : ramène
  /// l'utilisateur sur l'écran "Aujourd'hui".
  final void Function(String city) onCitySelected;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(FavoritesController controller) async {
    FocusScope.of(context).unfocus();
    await controller.search(_searchController.text);
  }

  Future<void> _addCity(
    FavoritesController favorites,
    CitySuggestion suggestion,
  ) async {
    await favorites.addFavorite(suggestion);
    _searchController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${suggestion.name} ajoutée aux favoris.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesController>();
    final weather = context.watch<WeatherController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ajouter une ville (ex. Marseille)',
                    prefixIcon: const Icon(Icons.location_city),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(favorites),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Rechercher des villes',
                onPressed:
                    favorites.searching ? null : () => _search(favorites),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        if (favorites.searching)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
        if (favorites.error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              favorites.error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (favorites.suggestions.isNotEmpty) ...[
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final suggestion in favorites.suggestions)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.add_location_alt_outlined),
                    title: Text(suggestion.name),
                    subtitle: Text(
                      [
                        if (suggestion.state != null) suggestion.state!,
                        suggestion.country,
                      ].join(', '),
                    ),
                    trailing: IconButton(
                      tooltip: 'Ajouter aux favoris',
                      icon: const Icon(Icons.add),
                      onPressed: () => _addCity(favorites, suggestion),
                    ),
                  ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mes villes favorites',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: favorites.favorites.isEmpty
              ? Center(
                  child: Text(
                    'Aucun favori pour le moment.\n'
                    'Recherchez une ville ci-dessus pour l\'ajouter.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: favorites.favorites.length,
                  itemBuilder: (context, index) {
                    final city = favorites.favorites[index];
                    final cached = favorites.cachedWeather[city];
                    final subtitle = cached != null
                        ? '${cached.description.capitalized} — '
                            '${cached.temperature.toStringAsFixed(1).replaceAll('.', ',')} °C'
                        : 'Météo non disponible hors-ligne';
                    return ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: Text(city),
                      subtitle: Text(subtitle),
                      selected: city == weather.city,
                      trailing: IconButton(
                        tooltip: 'Retirer des favoris',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => favorites.removeFavorite(city),
                      ),
                      onTap: () => widget.onCitySelected(city),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
