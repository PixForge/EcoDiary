import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'stats_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CatalogScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60,
        backgroundColor: theme.scaffoldBackgroundColor,
        color: const Color(0xFF2E7D32),
        animationDuration: const Duration(milliseconds: 300),
        buttonBackgroundColor: const Color(0xFF2E7D32),
        onTap: (index) {
          print('[MainNav] Переключение на вкладку $index');
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          Icon(Icons.home_outlined, size: 30, color: Colors.white),
          Icon(Icons.add_circle_outline, size: 30, color: Colors.white),
          Icon(Icons.bar_chart_outlined, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}
