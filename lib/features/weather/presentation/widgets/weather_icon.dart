import 'package:flutter/material.dart';

/// Icône météo OpenWeatherMap avec repli sur une icône Material
/// lorsque le réseau est indisponible.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({super.key, required this.iconCode, this.size = 48});

  final String iconCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://openweathermap.org/img/wn/$iconCode@${size >= 100 ? '4x' : '2x'}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.cloud_outlined,
        size: size * 0.8,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
