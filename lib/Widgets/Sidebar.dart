import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neerad_store/Providers/SettingsProvider.dart';
import 'package:neerad_store/Styles/AppStyles.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsProvider>().isDarkMode;

    return Container(
      width: 100,
      color: AppStyles.getSidebarBg(isDark),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _SidebarItem(
            icon: Icons.receipt_long,
            isSelected: currentIndex == 0,
            onTap: () => onItemSelected(0),
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.inventory_2,
            isSelected: currentIndex == 1,
            onTap: () => onItemSelected(1),
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.search,
            isSelected: currentIndex == 2,
            onTap: () => onItemSelected(2),
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.history,
            isSelected: currentIndex == 3,
            onTap: () => onItemSelected(3),
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.settings,
            isSelected: currentIndex == 4,
            onTap: () => onItemSelected(4),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SidebarItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80,
        alignment: Alignment.center,
        child: Icon(icon),
      ),
    );
  }
}
