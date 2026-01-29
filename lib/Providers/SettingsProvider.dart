import 'package:flutter/material.dart';
import 'package:neerad_store/Services/DatabaseService.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _storeName = 'Neerad Store';
  String _currencySymbol = '₹';

  bool get isDarkMode => _isDarkMode;
  String get storeName => _storeName;
  String get currencySymbol => _currencySymbol;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseService();

    final darkModeVal = await db.getSetting('isDarkMode');
    if (darkModeVal != null) {
      _isDarkMode = darkModeVal == 'true';
    }

    final storeNameVal = await db.getSetting('storeName');
    if (storeNameVal != null) {
      _storeName = storeNameVal;
    }

    final currencyVal = await db.getSetting('currencySymbol');
    if (currencyVal != null) {
      _currencySymbol = currencyVal;
    }

    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await DatabaseService().setSetting('isDarkMode', value.toString());
  }

  Future<void> setStoreName(String name) async {
    _storeName = name;
    notifyListeners();
    await DatabaseService().setSetting('storeName', name);
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    await DatabaseService().setSetting('currencySymbol', symbol);
  }
}
