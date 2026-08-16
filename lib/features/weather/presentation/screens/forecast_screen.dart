import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/widgets/error_view.dart';
import '../../../../core/presentation/widgets/offline_banner.dart';
import '../../domain/entities/weather_entities.dart';
import '../controllers/weather_controller.dart';
import '../widgets/forecast_day_tile.dart';

/// Écran "Prévisions" : prévisions sur 5 jours (pas de 3 heures)
/// regroupées par journée, avec repli sur le cache hors-ligne.
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<WeatherController>();
    final forecast = controller.forecast;

    if (forecast == null) {
      if (controller.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return ErrorView(
        message: controller.error ??
            'Aucune prévision disponible. Recherchez d\'abord une ville.',
        onRetry: controller.refresh,
      );
    }

    // Regroupement des prévisions par journée.
    final groups = <String, List<ForecastItem>>{};
    for (final item in forecast.data.items) {
      final label = DateFormat('EEEE d MMMM', 'fr_FR').format(item.dateTime);
      groups.putIfAbsent(label, () => <ForecastItem>[]).add(item);
    }

    return Column(
      children: [
        if (forecast.fromCache)
          OfflineBanner(fetchedAt: forecast.fetchedAt),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Text(
            'Prévisions pour ${forecast.data.cityName}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final entry = groups.entries.elementAt(index);
                    return ForecastDayTile(
                      dayLabel: entry.key,
                      items: entry.value,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
