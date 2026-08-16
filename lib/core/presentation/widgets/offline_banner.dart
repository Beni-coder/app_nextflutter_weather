import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bandeau affiché lorsque les données présentées proviennent du cache
/// local (appareil hors-ligne ou API injoignable).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.fetchedAt});

  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = fetchedAt != null
        ? DateFormat('d MMMM à HH:mm', 'fr_FR').format(fetchedAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 20, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              formattedDate == null
                  ? 'Mode hors-ligne : données issues du cache local.'
                  : 'Mode hors-ligne : données en cache du $formattedDate.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
