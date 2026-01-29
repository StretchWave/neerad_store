import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neerad_store/Models/Product.dart';
import 'package:neerad_store/Models/Sale.dart';
import 'package:provider/provider.dart';
import 'package:neerad_store/Providers/SettingsProvider.dart';
import 'package:neerad_store/Services/DatabaseService.dart';
import 'package:neerad_store/Styles/AppStyles.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class BillingItem {
  final Product product;
  int quantity;

  BillingItem({required this.product, this.quantity = 1});
}

class _BillingScreenState extends State<BillingScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _discountController = TextEditingController(text: '0.00');
  final _nameFocusNode = FocusNode();
  final _rootFocusNode = FocusNode();
  String _barcodeBuffer = '';
  DateTime _lastKeyEventTime = DateTime.now();

  List<BillingItem> _currentItems = [];
  double _dailyProfit = 0.0;
  double _currentProfit = 0.0;
  double _totalAmount = 0.0;
  int? _hoveredIndex;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _discountController.dispose();
    _nameFocusNode.dispose();
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDailyProfit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rootFocusNode.requestFocus();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      // If gap is too large (>100ms), it's likely manual typing or separate scans
      if (now.difference(_lastKeyEventTime).inMilliseconds > 100) {
        _barcodeBuffer = '';
      }
      _lastKeyEventTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          _processBarcode(_barcodeBuffer);
          _barcodeBuffer = '';
        }
      } else if (event.character != null) {
        _barcodeBuffer += event.character!;
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    try {
      final product = await DatabaseService().findProduct(barcode);
      if (product != null) {
        _addProductToBilling(product);
      } else {
        _showError('Barcode $barcode not found');
      }
    } catch (e) {
      _showError('Scanner error: $e');
    }
  }

  Future<void> _loadDailyProfit() async {
    try {
      final profit = await DatabaseService().getDailyProfit();
      setState(() => _dailyProfit = profit);
    } catch (e) {
      print('Error loading daily profit: $e');
    }
  }

  Future<void> _addItem() async {
    final query = _searchController.text.isNotEmpty
        ? _searchController.text
        : _nameController.text;
    if (query.isEmpty) return;

    try {
      final product = await DatabaseService().findProduct(query);
      if (product != null) {
        _addProductToBilling(product);
      } else {
        _showError('Product not found');
      }
    } catch (e) {
      _showError('Search error: $e');
    }
  }

  void _addProductToBilling(Product product) {
    setState(() {
      final existingItemIndex = _currentItems.indexWhere(
        (item) => item.product.itemId == product.itemId,
      );

      if (existingItemIndex != -1) {
        _currentItems[existingItemIndex].quantity++;
      } else {
        _currentItems.add(BillingItem(product: product));
      }

      _calculateTotals();
      _searchController.clear();
      _nameController.clear();
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _currentItems[index].quantity += delta;
      if (_currentItems[index].quantity < 1) {
        _currentItems.removeAt(index);
      }
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    double total = 0.0;
    double profit = 0.0;
    double discount = double.tryParse(_discountController.text) ?? 0.0;

    for (var item in _currentItems) {
      total += (item.product.sellingPrice * item.quantity);
      profit +=
          (item.product.sellingPrice - item.product.originalPrice) *
          item.quantity;
    }

    setState(() {
      _totalAmount = total - discount;
      _currentProfit = profit - discount;
    });
  }

  void _removeItem(int index) {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.getDialogBgColor(isDark),
        title: Text(
          'Remove Item?',
          style: AppStyles.getDialogTitleStyle(isDark),
        ),
        content: Text(
          'Are you sure you want to remove this item?',
          style: AppStyles.getDialogTextStyle(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentItems.removeAt(index);
                _calculateTotals();
              });
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    if (_currentItems.isEmpty) return;

    final isDark = context.read<SettingsProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.getDialogBgColor(isDark),
        title: Text(
          'Clear All Items?',
          style: AppStyles.getDialogTitleStyle(isDark),
        ),
        content: Text(
          'This will remove all items from the current bill.',
          style: AppStyles.getDialogTextStyle(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentItems.clear();
                _discountController.text = '0.00';
                _calculateTotals();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeSale() async {
    if (_currentItems.isEmpty) return;

    try {
      double discount = double.tryParse(_discountController.text) ?? 0.0;

      // Generate a unique transaction ID based on timestamp
      final String transactionId =
          'TXN${DateTime.now().millisecondsSinceEpoch}';

      // Calculate total number of units sold to distribute discount
      int totalUnits = 0;
      for (var item in _currentItems) {
        totalUnits += item.quantity;
      }

      double discountPerUnit = totalUnits > 0 ? discount / totalUnits : 0.0;

      for (var item in _currentItems) {
        final sale = Sale(
          itemId: item.product.itemId,
          itemName: item.product.itemName,
          quantity: item.quantity,
          discount: discountPerUnit * item.quantity,
          profit:
              ((item.product.sellingPrice - item.product.originalPrice) *
                  item.quantity) -
              (discountPerUnit * item.quantity),
          totalPrice:
              (item.product.sellingPrice * item.quantity) -
              (discountPerUnit * item.quantity),
          transactionId: transactionId,
        );
        await DatabaseService().addSale(sale);
      }

      _showSuccess('Sale finalized!');
      setState(() {
        _currentItems.clear();
        _totalAmount = 0.0;
        _currentProfit = 0.0;
        _discountController.text = '0.00';
      });
      await _loadDailyProfit();
    } catch (e) {
      _showError('Failed to finalize sale: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;

    return GestureDetector(
      onTap: () {
        if (!FocusScope.of(context).hasPrimaryFocus) {
          _rootFocusNode.requestFocus();
        }
      },
      child: KeyboardListener(
        focusNode: _rootFocusNode,
        onKeyEvent: _handleKeyEvent,
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Billing:',
                    style: AppStyles.getScreenTitleStyle(isDark),
                  ),
                  Text(
                    'DP: ${_dailyProfit.toStringAsFixed(2)}',
                    style: AppStyles.dpPriceStyle,
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildInputRow(
                          'Item ID:',
                          'Scan the Bar code here!',
                          _searchController,
                          isDark,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Item Name:',
                                style: AppStyles.getLabelStyle(isDark),
                              ),
                            ),
                            Expanded(
                              child: RawAutocomplete<Product>(
                                textEditingController: _nameController,
                                focusNode: _nameFocusNode,
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) async {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<Product>.empty();
                                      }
                                      return await DatabaseService()
                                          .searchSuggestions(
                                            textEditingValue.text,
                                          );
                                    },
                                displayStringForOption: (Product option) =>
                                    option.itemName,
                                onSelected: (Product selection) {
                                  _addProductToBilling(selection);
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      return SizedBox(
                                        height: 45,
                                        child: TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          onSubmitted: (value) {
                                            _addItem();
                                          },
                                          style: TextStyle(
                                            color: AppStyles.getTextColor(
                                              isDark,
                                            ),
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Type the item to search here',
                                            hintStyle: TextStyle(
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                            fillColor: AppStyles.getInputBg(
                                              isDark,
                                            ),
                                            filled: true,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4.0,
                                      color: AppStyles.getDialogBgColor(isDark),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 400,
                                        constraints: const BoxConstraints(
                                          maxHeight: 250,
                                        ),
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final Product option = options
                                                .elementAt(index);
                                            return InkWell(
                                              onTap: () => onSelected(option),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: isDark
                                                          ? Colors.white12
                                                          : Colors.black12,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      option.itemName,
                                                      style: TextStyle(
                                                        color:
                                                            AppStyles.getTextColor(
                                                              isDark,
                                                            ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '₹${option.sellingPrice.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black54,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryTeal,
                          minimumSize: const Size(120, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Add', style: AppStyles.buttonText),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'P: ${_currentProfit.toStringAsFixed(2)}',
                        style: AppStyles.dpPriceStyle,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Discount:  ',
                            style: AppStyles.getLabelStyle(isDark),
                          ),
                          SizedBox(
                            width: 120,
                            height: 40,
                            child: TextField(
                              controller: _discountController,
                              onChanged: (_) => _calculateTotals(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppStyles.getTextColor(isDark),
                              ),
                              decoration: InputDecoration(
                                fillColor: AppStyles.getInputBg(isDark),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Total: ${settings.currencySymbol}${_totalAmount.toStringAsFixed(2)}',
                        style: AppStyles.getScreenTitleStyle(
                          isDark,
                        ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _finalizeSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(150, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Finalize Sale',
                          style: AppStyles.buttonText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildTable(settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    String hint,
    TextEditingController controller,
    bool isDark,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: AppStyles.getLabelStyle(isDark)),
        ),
        Expanded(
          child: SizedBox(
            height: 45,
            child: TextField(
              controller: controller,
              onSubmitted: (value) => _addItem(),
              style: TextStyle(color: AppStyles.getTextColor(isDark)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                fillColor: AppStyles.getInputBg(isDark),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
        ),
        child: Column(
          children: [
            Container(
              color: AppStyles.getTableHeaderBg(isDark),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      'Sl',
                      style: AppStyles.getTableHeaderStyle(isDark),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Product Name',
                      style: AppStyles.getTableHeaderStyle(isDark),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Quantity',
                      textAlign: TextAlign.center,
                      style: AppStyles.getTableHeaderStyle(isDark),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Price',
                      textAlign: TextAlign.center,
                      style: AppStyles.getTableHeaderStyle(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _currentItems.length,
                itemBuilder: (context, index) {
                  final item = _currentItems[index];
                  final isHovered = _hoveredIndex == index;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: AppStyles.getTextColor(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              item.product.itemName,
                              style: TextStyle(
                                color: AppStyles.getTextColor(isDark),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isHovered)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 18,
                                    ),
                                    onPressed: () => _updateQuantity(index, -1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    item.quantity.toString(),
                                    style: TextStyle(
                                      color: AppStyles.getTextColor(isDark),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isHovered)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 18,
                                    ),
                                    onPressed: () => _updateQuantity(index, 1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                if (isHovered) const SizedBox(width: 8),
                                if (isHovered)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeItem(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${settings.currencySymbol}${(item.product.sellingPrice * item.quantity).toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppStyles.getTextColor(isDark),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
