import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../lost_found/views/dashboard_screen.dart';
import '../../lost_found/views/explore_screen.dart';
import '../../lost_found/views/report_item_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const ExploreScreen(),
    ReportItemScreen(
      onSubmitted: () => setState(() => _currentIndex = 0),
    ),
    const ChatListScreen(),
    const DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: AppTheme.primaryColor),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box_rounded, color: AppTheme.primaryColor),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppTheme.primaryColor),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
