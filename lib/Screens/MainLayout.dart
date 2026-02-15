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
  final GlobalKey<BillingScreenState> _billingKey = GlobalKey();

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
              // Restore scanner focus when switching back to Billing Screen
              if (index == 0) {
                // Small delay to ensure widget is visible/onstage before requesting focus
                Future.delayed(const Duration(milliseconds: 50), () {
                  _billingKey.currentState?.requestScannerFocus();
                });
              }
            },
          ),
          Expanded(
            child: Stack(
              children: [
                // Keep BillingScreen (index 0) alive to preserve Cart
                Offstage(
                  offstage: _currentIndex != 0,
                  child: BillingScreen(key: _billingKey),
                ),
                // Rebuild other screens on every visit to force data reload
                if (_currentIndex == 1) const ProductScreen(),
                if (_currentIndex == 2) const InventoryScreen(),
                if (_currentIndex == 3) const SalesScreen(),
                if (_currentIndex == 4) const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
