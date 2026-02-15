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
  @override
  State<BillingScreen> createState() => BillingScreenState();
}

class BillingItem {
  final Product product;
  int quantity;

  BillingItem({required this.product, this.quantity = 1});
}

class BillingScreenState extends State<BillingScreen> {
  final _searchController = TextEditingController();

  // Public method to reclaim focus
  void requestScannerFocus() {
    _rootFocusNode.requestFocus();
  }

  String _encodeToAlphabets(double value) {
    if (value == 0)
      return 'J.JJ'; // Or just J based on preference, but 0.00 -> J.JJ matches pattern

    // Format to 2 decimal places first to match standard currency display
    String formatted = value.abs().toStringAsFixed(2);
    String encoded = '';

    // Map digits 1-9 to A-I, 0 to J
    final map = {
      '1': 'A', '2': 'B', '3': 'C', '4': 'D', '5': 'E',
      '6': 'F', '7': 'G', '8': 'H', '9': 'I', '0': 'J',
      '.': '.', '-': '-', // Keep decimal and negative sign
    };

    for (int i = 0; i < formatted.length; i++) {
      encoded += map[formatted[i]] ?? formatted[i];
    }

    return value < 0 ? '-$encoded' : encoded;
  }

  final _nameController = TextEditingController();
  final _discountController = TextEditingController(text: '0.00');
  final _nameFocusNode = FocusNode();
  final _rootFocusNode = FocusNode();
  // Added separate focus node for search field to track its focus state
  final _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
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

  void _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // Prevent processing if text fields are focused to avoid double entry
      if (_searchFocusNode.hasFocus || _nameFocusNode.hasFocus) {
        return;
      }

      final now = DateTime.now();

      // DEBUG: Log keys to see if scanner is working
      print(
        'DEBUG: Key received: ${event.logicalKey.keyLabel} (Code: ${event.logicalKey}) Char: ${event.character}',
      );

      // Increased timeout to 500ms to be more forgiving for different scanners/system speeds
      if (now.difference(_lastKeyEventTime).inMilliseconds > 500) {
        _barcodeBuffer = '';
      }
      _lastKeyEventTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_barcodeBuffer.isNotEmpty) {
          _processBarcode(_barcodeBuffer);
          _barcodeBuffer = '';
        } else if (_currentItems.isNotEmpty) {
          _finalizeSale();
        }
      } else if (event.character != null) {
        // Only add printable characters to the buffer
        if (!_isControlChar(event.character!)) {
          _barcodeBuffer += event.character!;
          // DEBUG: Show buffer growth
          print('DEBUG: Buffer: $_barcodeBuffer');
        }
      }
    }
  }

  bool _isControlChar(String char) {
    if (char.isEmpty) return true;
    final codeUnit = char.codeUnitAt(0);
    // 0-31 are control chars, 127 is delete
    return codeUnit < 32 || codeUnit == 127;
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
    _rootFocusNode.requestFocus();
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
    _rootFocusNode.requestFocus();
  }

  Future<void> _addCustomItem() async {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.getDialogBgColor(isDark),
        title: Text(
          'Add Custom Item',
          style: AppStyles.getDialogTitleStyle(isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppStyles.getTextColor(isDark)),
              decoration: InputDecoration(
                hintText: 'Enter Price',
                labelText: 'Price',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price != null && price > 0) {
                final customProduct = Product(
                  itemId: 'UNKNOWN',
                  itemName: 'Custom Item',
                  originalPrice: 0, // Unknown cost
                  sellingPrice: price,
                  quantity: 1, // Not tracked in inventory really
                );
                _addProductToBilling(customProduct);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => _rootFocusNode.requestFocus());
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
    ).then((_) => _rootFocusNode.requestFocus());
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
    ).then((_) => _rootFocusNode.requestFocus());
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
    _rootFocusNode.requestFocus();
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

    return Focus(
      focusNode: _rootFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(node, event);
        return KeyEventResult.ignored; // Allow propagation
      },
      child: GestureDetector(
        onTap: () {
          // If the user taps outside any input field, reclaim focus for the scanner
          if (!_searchFocusNode.hasFocus && !_nameFocusNode.hasFocus) {
            _rootFocusNode.requestFocus();
          }
        },
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DP: ${_encodeToAlphabets(_dailyProfit)}',
                        style: AppStyles.dpPriceStyle,
                      ),
                      Text(
                        'P: ${_encodeToAlphabets(_currentProfit)}',
                        style: AppStyles.dpPriceStyle.copyWith(
                          fontSize: 16,
                          color: _currentProfit >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
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
                          focusNode: _searchFocusNode,
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
                                optionsViewBuilder:
                                    (context, onSelected, options) {
                                      return _SearchResultsOverlay(
                                        options: options,
                                        onSelected: onSelected,
                                        isDark: isDark,
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
                      ElevatedButton(
                        onPressed: _addCustomItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(120, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Custom',
                          style: AppStyles.buttonText,
                        ),
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
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBillingTable(isDark)),
              const SizedBox(height: 20),
              _buildTotalSection(isDark),
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
    bool isDark, {
    FocusNode? focusNode,
  }) {
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
              focusNode: focusNode,
              style: TextStyle(color: AppStyles.getTextColor(isDark)),
              onSubmitted: (_) {
                if (controller == _searchController) {
                  _addItem();
                }
              },
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

  Widget _buildBillingTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: AppStyles.getTableHeaderBg(isDark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
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
                    'Item Name',
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
                SizedBox(
                  width: 120,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _currentItems.length,
              itemBuilder: (context, index) {
                final item = _currentItems[index];
                final isHovered = _hoveredIndex == index;
                final itemTotal = item.product.sellingPrice * item.quantity;
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHovered
                          ? (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100])
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 20,
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            '₹${item.product.sellingPrice.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppStyles.getTextColor(isDark),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: _buildQuantityControl(
                            index,
                            item.quantity,
                            isDark,
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            '₹${itemTotal.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppStyles.getTextColor(isDark),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeItem(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
    );
  }

  Widget _buildQuantityControl(int index, int quantity, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          onPressed: () => _updateQuantity(index, -1),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppStyles.getTextColor(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          onPressed: () => _updateQuantity(index, 1),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildTotalSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppStyles.getTableHeaderBg(isDark),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Discount: ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.getTextColor(isDark),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  onChanged: (value) => _calculateTotals(),
                  decoration: const InputDecoration(
                    prefixText: '₹',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Total: ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.getTextColor(isDark),
                ),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 40),
              ElevatedButton(
                onPressed: _finalizeSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryTeal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Finalize', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResultsOverlay extends StatefulWidget {
  final Iterable<Product> options;
  final AutocompleteOnSelected<Product> onSelected;
  final bool isDark;

  const _SearchResultsOverlay({
    required this.options,
    required this.onSelected,
    required this.isDark,
  });

  @override
  State<_SearchResultsOverlay> createState() => _SearchResultsOverlayState();
}

class _SearchResultsOverlayState extends State<_SearchResultsOverlay> {
  int _visibleCount = 5;

  @override
  Widget build(BuildContext context) {
    final displayedOptions = widget.options.take(_visibleCount).toList();
    final hasMore = widget.options.length > _visibleCount;

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        color: AppStyles.getDialogBgColor(widget.isDark),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: displayedOptions.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Product option = displayedOptions[index];
                    return InkWell(
                      onTap: () => widget.onSelected(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: widget.isDark
                                  ? Colors.white12
                                  : Colors.black12,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option.itemName,
                              style: TextStyle(
                                color: AppStyles.getTextColor(widget.isDark),
                              ),
                            ),
                            Row(
                              children: [
                                if (option.quantity != null &&
                                    option.quantity == 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      'Out of Stock',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  '₹${option.sellingPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: widget.isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (hasMore)
                InkWell(
                  onTap: () {
                    setState(() {
                      _visibleCount += 5;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: widget.isDark ? Colors.white10 : Colors.grey[200],
                    child: Center(
                      child: Text(
                        'Show More (${widget.options.length - _visibleCount} remaining)',
                        style: TextStyle(
                          color: AppStyles.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
