import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/home/presentation/pages/home_page.dart';
import 'package:local_vault/features/memory/presentation/pages/memory_management_page.dart';
import 'package:local_vault/features/settings/presentation/pages/settings_page.dart';
import 'package:local_vault/features/template/presentation/pages/template_page.dart';

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
    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '模板',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_alt_outlined),
            label: '记忆',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
