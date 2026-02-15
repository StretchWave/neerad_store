import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neerad_store/Providers/SettingsProvider.dart';
import 'package:neerad_store/Models/Product.dart';
import 'package:neerad_store/Services/DatabaseService.dart';
import 'package:neerad_store/Styles/AppStyles.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await DatabaseService().getAllProducts();
      setState(() {
        _allProducts = products;
        _filterProducts();
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts.where((p) {
        return p.itemName.toLowerCase().contains(query) ||
            p.itemId.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.getDialogBgColor(isDark),
        title: Text(
          'Delete Product?',
          style: AppStyles.getDialogTitleStyle(isDark),
        ),
        content: Text(
          'Are you sure you want to delete "${product.itemName}"?',
          style: AppStyles.getDialogTextStyle(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().deleteProduct(product.itemId);
      _loadProducts();
    }
  }

  Future<void> _editProduct(Product product) async {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    final nameController = TextEditingController(text: product.itemName);
    final origPriceController = TextEditingController(
      text: product.originalPrice.toString(),
    );
    final sellPriceController = TextEditingController(
      text: product.sellingPrice.toString(),
    );
    final qtyController = TextEditingController(
      text: product.quantity?.toString() ?? '',
    );

    // Initialize profit for initial display
    double currentProfit = product.sellingPrice - product.originalPrice;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void updateProfit() {
              final orig = double.tryParse(origPriceController.text) ?? 0.0;
              final sell = double.tryParse(sellPriceController.text) ?? 0.0;
              setStateDialog(() {
                currentProfit = sell - orig;
              });
            }

            // We need to attach listeners only once, but StatefulBuilder builder is called on rebuilds.
            // A better way for these simple dialogs is to use onChanged in TextField or just handle listener setup outside if possible.
            // However, since we defined controllers outside, we can just hook up onChanged.

            return AlertDialog(
              backgroundColor: AppStyles.getDialogBgColor(isDark),
              title: Text(
                'Edit Product',
                style: AppStyles.getDialogTitleStyle(isDark),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: AppStyles.getTextColor(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    TextField(
                      controller: origPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => updateProfit(),
                      style: TextStyle(color: AppStyles.getTextColor(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Original Price',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    TextField(
                      controller: sellPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => updateProfit(),
                      style: TextStyle(color: AppStyles.getTextColor(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Selling Price',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Profit: ${context.read<SettingsProvider>().currencySymbol}${currentProfit.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: currentProfit >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppStyles.getTextColor(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedProduct = Product(
                      id: product.id,
                      itemId: product.itemId, // ID not editable here logic
                      itemName: nameController.text,
                      originalPrice:
                          double.tryParse(origPriceController.text) ?? 0.0,
                      sellingPrice:
                          double.tryParse(sellPriceController.text) ?? 0.0,
                      quantity: int.tryParse(qtyController.text),
                    );
                    await DatabaseService().updateProduct(updatedProduct);
                    Navigator.pop(context);
                    _loadProducts();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inventory:', style: AppStyles.getScreenTitleStyle(isDark)),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _filterProducts()),
                  style: TextStyle(color: AppStyles.getTextColor(isDark)),
                  decoration: InputDecoration(
                    hintText: 'Search by Name or ID',
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
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
          Expanded(child: _buildTable(isDark, settings)),
        ],
      ),
    );
  }

  Widget _buildTable(bool isDark, SettingsProvider settings) {
    return Container(
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
                SizedBox(
                  width: 100,
                  child: Text(
                    'ID',
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Name',
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
                  width: 80,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Action',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = _filteredProducts[index];
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
                            color: isHovered
                                ? (isDark ? Colors.white10 : Colors.grey[200])
                                : null,
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
                              SizedBox(
                                width: 100,
                                child: Text(
                                  p.itemId,
                                  style: TextStyle(
                                    color: AppStyles.getTextColor(isDark),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  p.itemName,
                                  style: TextStyle(
                                    color: AppStyles.getTextColor(isDark),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '${settings.currencySymbol}${p.sellingPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppStyles.getTextColor(isDark),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: (p.quantity != null && p.quantity == 0)
                                    ? Text(
                                        'Out of Stock',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        p.quantity?.toString() ?? '-',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppStyles.getTextColor(isDark),
                                        ),
                                      ),
                              ),
                              SizedBox(
                                width: 100,
                                child: isHovered
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            onPressed: () => _editProduct(p),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () => _deleteProduct(p),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
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
}
