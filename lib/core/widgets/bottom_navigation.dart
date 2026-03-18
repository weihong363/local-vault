import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/home/presentation/pages/home_page.dart';
import 'package:local_vault/features/memory/presentation/pages/memory_management_page.dart';
import 'package:local_vault/features/settings/presentation/pages/settings_page.dart';
import 'package:local_vault/features/template/presentation/pages/template_page.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    this.currentIndex = 0,
  });

  final int currentIndex;

  static const List<Widget> _pages = [
    HomePage(),
    TemplatePage(),
    MemoryManagementPage(),
    SettingsPage(),
  ];

  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.template,
    AppRoutes.memoryManagement,
    AppRoutes.settings,
  ];

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: loc.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: loc.navTemplates,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.psychology_alt_outlined),
            label: loc.navMemory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: loc.navSettings,
          ),
        ],
      ),
    );
  }
}
