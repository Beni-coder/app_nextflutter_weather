import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/string_utils.dart';
import '../../domain/entities/weather_entities.dart';
import '../widgets/weather_icon.dart';

/// Tuile résumant les prévisions d'une journée (min/max, icône) avec
/// le détail par pas de 3 heures dépliable.
class ForecastDayTile extends StatelessWidget {
  const ForecastDayTile({super.key, required this.dayLabel, required this.items});

  final String dayLabel;
  final List<ForecastItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minTemp = items
        .map((item) => item.temperature)
        .reduce((a, b) => a < b ? a : b);
    final maxTemp = items
        .map((item) => item.temperature)
        .reduce((a, b) => a > b ? a : b);

    // Icône représentative : l'élément le plus proche de midi.
    final representative = items.reduce(
      (a, b) =>
          (a.dateTime.hour - 12).abs() <= (b.dateTime.hour - 12).abs() ? a : b,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: WeatherIcon(iconCode: representative.iconCode, size: 44),
        title: Text(
          dayLabel.capitalized,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(representative.description.capitalized),
        trailing: Text(
          '${NumberFormat('0', 'fr_FR').format(maxTemp)}° / '
          '${NumberFormat('0', 'fr_FR').format(minTemp)}°',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        children: [
          for (final item in items)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: WeatherIcon(iconCode: item.iconCode, size: 34),
              title: Text(DateFormat('HH:mm').format(item.dateTime)),
              subtitle: Text(item.description.capitalized),
              trailing: Text(
                '${NumberFormat('0.0', 'fr_FR').format(item.temperature)} °C',
                style: theme.textTheme.bodyLarge,
              ),
            ),
        ],
      ),
    );
  }
}
