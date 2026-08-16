import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/widgets/error_view.dart';
import '../../../../core/presentation/widgets/offline_banner.dart';
import '../controllers/weather_controller.dart';
import '../widgets/current_weather_card.dart';

/// Écran "Aujourd'hui" : météo actuelle de la ville sélectionnée,
/// recherche de ville et bandeau hors-ligne.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final city = _searchController.text.trim();
    if (city.isEmpty) return;
    FocusScope.of(context).unfocus();
    await context.read<WeatherController>().changeCity(city);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<WeatherController>();
    final current = controller.current;

    return Column(
      children: [
        if (controller.isOffline)
          OfflineBanner(
            fetchedAt:
                current?.fetchedAt ?? controller.forecast?.fetchedAt,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une ville (ex. Lyon)',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Rechercher',
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
              IconButton.outlined(
                tooltip: 'Actualiser',
                onPressed:
                    controller.loading ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (controller.error != null && current == null) ...[
          Expanded(
            child: ErrorView(
              message: controller.error!,
              onRetry: controller.refresh,
            ),
          ),
        ] else if (controller.loading && current == null) ...[
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ] else if (current != null) ...[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${current.data.cityName}'
                    '${current.data.country != null ? ', ${current.data.country}' : ''}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CurrentWeatherCard(weather: current.data),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          const Expanded(
            child: Center(
              child: Text('Recherchez une ville pour afficher sa météo.'),
            ),
          ),
        ],
      ],
    );
  }
}
