import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'tournament_screen.dart';
import 'tasks_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  final List<Widget> _pages = [
    TasksScreen(),
    CalendarScreen(),
    FriendsScreen(),
    TournamentScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final navColors = [
      Theme.of(context).colorScheme.primary, // Tasks
      Theme.of(context).colorScheme.primary, // Calendar
      Theme.of(context).colorScheme.primary, // Friends
      Theme.of(context).colorScheme.primary, // Tournament
      Theme.of(context).colorScheme.primary, // Profile
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withAlpha(240),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(120), width: 1.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: NavigationBar(
            height: 65,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            indicatorColor: navColors[_selectedIndex].withAlpha(25),
            destinations: [
              _buildNavigationDestination(
                icon: Icons.task_alt_rounded,
                label: 'Tasks',
                isSelected: _selectedIndex == 0,
                color: navColors[0],
              ),
              _buildNavigationDestination(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                isSelected: _selectedIndex == 1,
                color: navColors[1],
              ),
              _buildNavigationDestination(
                icon: Icons.groups_3_rounded,
                label: 'Friends',
                isSelected: _selectedIndex == 2,
                color: navColors[2],
              ),
              _buildNavigationDestination(
                icon: Icons.emoji_events_rounded,
                label: 'Tournament',
                isSelected: _selectedIndex == 3,
                color: navColors[3],
              ),
              _buildNavigationDestination(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: _selectedIndex == 4,
                color: navColors[4],
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavigationDestination({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        size: 24,
        color: isSelected ? color : Theme.of(context).colorScheme.primary,
      ),
      selectedIcon: Icon(
        icon,
        size: 24,
        color: color,
      ),
      label: label,
    );
  }
}
