import 'package:flutter/material.dart';
import 'dart:ui';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> with TickerProviderStateMixin {
  List<AnimationController> _navAnimationControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
  }

  void _initializeAnimationControllers() {
    _navAnimationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _navAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildBottomNavItem(
                icon: item.icon,
                label: item.label,
                isActive: widget.currentIndex == index,
                onTap: () => widget.onTap(index),
                index: index,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required int index,
  }) {
    // Safety check to ensure animation controllers are initialized
    if (_navAnimationControllers.isEmpty || index >= _navAnimationControllers.length) {
      // Return a simple container without animation if controllers aren't ready
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 12,
            vertical: isActive ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Trigger bounce animation
        _navAnimationControllers[index].forward().then((_) {
          _navAnimationControllers[index].reverse();
        });
        
        onTap();
      },
      child: AnimatedBuilder(
        animation: _navAnimationControllers[index],
        builder: (context, child) {
          // Simple bounce scale animation
          final scale = 1.0 + (_navAnimationControllers[index].value * 0.3);
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 12,
                vertical: isActive ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isActive ? Colors.white : Colors.grey[600],
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.label,
  });
}
