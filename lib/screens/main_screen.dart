import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'alerts_dashboard_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AlertsDashboardScreen(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home,
      label: 'Home',
      color: AppColors.primary,
    ),
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      color: AppColors.secondary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;

              return _buildNavItem(item, index, isSelected);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BottomNavItem item, int index, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? item.color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      color: isSelected ? item.color : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.color
                                    .withOpacity(0.3 * _animation.value),
                                blurRadius: 8 * _animation.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 8 : 0,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: isSelected
                    ? Text(
                        item.label,
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      // Reset and replay animation for the new active item
      _animationController.reset();
      _animationController.forward();

      // Haptic feedback for better UX
      // HapticFeedback.selectionClick();
    }
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
