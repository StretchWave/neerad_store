import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neerad_store/Providers/SettingsProvider.dart';
import 'package:neerad_store/Styles/AppStyles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _storeNameController = TextEditingController(text: settings.storeName);
    _currencyController = TextEditingController(text: settings.currencySymbol);
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings:', style: AppStyles.getScreenTitleStyle(isDark)),
          const SizedBox(height: 60),
          Center(
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    'Dark Mode:',
                    Switch(
                      value: settings.isDarkMode,
                      activeColor: AppStyles.primaryTeal,
                      onChanged: (value) => settings.toggleDarkMode(value),
                    ),
                    isDark,
                  ),
                  const Divider(height: 40),
                  _buildInputSetting(
                    'Store Name:',
                    _storeNameController,
                    'Enter store name',
                    (value) => settings.setStoreName(value),
                    isDark,
                  ),
                  const Divider(height: 40),
                  _buildInputSetting(
                    'Currency Symbol:',
                    _currencyController,
                    'e.g. ₹, \$',
                    (value) => settings.setCurrencySymbol(value),
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget action, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.getLabelStyle(
            isDark,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        action,
      ],
    );
  }

  Widget _buildInputSetting(
    String label,
    TextEditingController controller,
    String hint,
    Function(String) onSave,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppStyles.getLabelStyle(
              isDark,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: onSave,
                  style: TextStyle(color: AppStyles.getTextColor(isDark)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    fillColor: isDark ? const Color(0xFF3D3D3D) : Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: isDark
                          ? BorderSide.none
                          : const BorderSide(color: Colors.black12),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save, color: AppStyles.primaryTeal),
                onPressed: () => onSave(controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
