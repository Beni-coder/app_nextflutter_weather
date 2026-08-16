import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/screens/profile_screen.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/weather_controller.dart';
import 'favorites_screen.dart';
import 'forecast_screen.dart';
import 'home_screen.dart';

/// Coquille de navigation principale : 4 onglets
/// (Aujourd'hui, Prévisions, Favoris, Profil).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final weather = context.read<WeatherController>();
    final favorites = context.read<FavoritesController>();
    weather.initializeIfNeeded();
    favorites.load();
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.read<WeatherController>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const ForecastScreen(),
          FavoritesScreen(
            onCitySelected: (city) {
              weather.changeCity(city);
              setState(() => _currentIndex = 0);
            },
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Aujourd\'hui',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Prévisions',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
