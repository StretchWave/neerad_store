import 'package:flutter/material.dart';
import 'package:neerad_store/Screens/BillingScreen.dart';
import 'package:neerad_store/Screens/InventoryScreen.dart';
import 'package:neerad_store/Screens/ProductScreen.dart';
import 'package:neerad_store/Screens/SalesScreen.dart';
import 'package:neerad_store/Screens/SettingsScreen.dart';
import 'package:neerad_store/Widgets/Sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BillingScreen(),
    const ProductScreen(),
    const InventoryScreen(),
    const SalesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}
