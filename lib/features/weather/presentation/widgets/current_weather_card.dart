import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/string_utils.dart';
import '../../domain/entities/weather_entities.dart';
import '../widgets/weather_icon.dart';

/// Carte principale affichant la météo actuelle d'une ville.
class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({super.key, required this.weather});

  final CurrentWeather weather;

  String _formatTemperature(double value) =>
      NumberFormat('0.0', 'fr_FR').format(value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatTemperature(weather.temperature)} °C',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Ressenti ${_formatTemperature(weather.feelsLike)} °C',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                WeatherIcon(iconCode: weather.iconCode, size: 110),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.description.capitalized,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE d MMMM', 'fr_FR')
                            .format(weather.observedAt)
                            .capitalized,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            _DetailsGrid(weather: weather),
          ],
        ),
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.weather});

  final CurrentWeather weather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <(IconData, String, String)>[
      (
        Icons.thermostat_outlined,
        'Minimum / Maximum',
        '${NumberFormat('0.0', 'fr_FR').format(weather.tempMin)} °C / '
            '${NumberFormat('0.0', 'fr_FR').format(weather.tempMax)} °C'
      ),
      (
        Icons.water_drop_outlined,
        'Humidité',
        '${weather.humidity} %'
      ),
      (
        Icons.air,
        'Vent',
        '${NumberFormat('0.0', 'fr_FR').format(weather.windSpeed * 3.6)} km/h'
      ),
      (
        Icons.speed_outlined,
        'Pression',
        '${weather.pressure} hPa'
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.4,
      children: [
        for (final (icon, label, value) in details)
          Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
