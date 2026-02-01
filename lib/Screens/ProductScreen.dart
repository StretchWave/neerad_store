import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neerad_store/Providers/SettingsProvider.dart';
import 'package:neerad_store/Models/Product.dart';
import 'package:neerad_store/Services/DatabaseService.dart';
import 'package:neerad_store/Styles/AppStyles.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isEditing = false;
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
      setState(() => _products = products);
    } catch (e) {
      _showError('Failed to load products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _originalPriceController.text.isEmpty ||
        _sellingPriceController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    String itemId = _idController.text;
    if (itemId.isEmpty) {
      if (_isEditing) {
        // Should not happen as ID is read-only in edit, but safety check
        _showError('Item ID cannot be empty on update');
        return;
      }
      try {
        itemId = await DatabaseService().getNextAvailableId();
      } catch (e) {
        _showError('Failed to generate Item ID: $e');
        return;
      }
    }

    final product = Product(
      itemId: itemId,
      itemName: _nameController.text,
      originalPrice: double.tryParse(_originalPriceController.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
      quantity: _quantityController.text.isNotEmpty
          ? int.tryParse(_quantityController.text)
          : null,
    );

    try {
      if (_isEditing) {
        await DatabaseService().updateProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      } else {
        await DatabaseService().addProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
      _clearInputs();
      setState(() {
        _isEditing = false;
      });
      await _loadProducts();
    } catch (e) {
      _showError('Failed to save product: $e');
    }
  }

  void _editProduct(Product product) {
    setState(() {
      _isEditing = true;
      _idController.text = product.itemId;
      _nameController.text = product.itemName;
      _originalPriceController.text = product.originalPrice.toString();
      _sellingPriceController.text = product.sellingPrice.toString();
      _quantityController.text = product.quantity?.toString() ?? '';
    });
  }

  Future<void> _deleteProduct(String itemId) async {
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
          'Are you sure you want to delete this product? This action cannot be undone.',
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
      try {
        await DatabaseService().deleteProduct(itemId);
        await _loadProducts();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product deleted')));
      } catch (e) {
        _showError('Failed to delete product: $e');
      }
    }
  }

  void _clearInputs() {
    setState(() {
      _isEditing = false;
    });
    _nameController.clear();
    _idController.clear();
    _originalPriceController.clear();
    _sellingPriceController.clear();
    _quantityController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
          Text('Add Products:', style: AppStyles.getScreenTitleStyle(isDark)),
          const SizedBox(height: 60),
          Center(
            child: SizedBox(
              width: 600,
              child: Column(
                children: [
                  _buildInputRow(
                    'Item Name:',
                    'Type the item to search here',
                    _nameController,
                    isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildInputRow(
                    'Item ID:',
                    _isEditing
                        ? 'Cannot change ID'
                        : 'Scan or leave empty for auto-ID',
                    _idController,
                    isDark,
                    readOnly: _isEditing,
                  ),
                  const SizedBox(height: 20),
                  _buildInputRow(
                    'Original Price:',
                    '',
                    _originalPriceController,
                    isDark,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  _buildInputRow(
                    'Selling Price:',
                    '',
                    _sellingPriceController,
                    isDark,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  _buildInputRow(
                    'Quantity:',
                    '(Optional)',
                    _quantityController,
                    isDark,
                    width: 120,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditing
                          ? Colors.orange
                          : AppStyles.primaryTeal,
                      minimumSize: const Size(120, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Update' : 'Submit',
                      style: AppStyles.buttonText,
                    ),
                  ),
                  if (_isEditing)
                    TextButton(
                      onPressed: _clearInputs,
                      child: Text(
                        'Cancel Edit',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    String hint,
    TextEditingController controller,
    bool isDark, {
    double? width,
    bool readOnly = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: AppStyles.getLabelStyle(isDark),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: width ?? 300,
          height: 45,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(color: AppStyles.getTextColor(isDark)),
            decoration: InputDecoration(
              hintText: readOnly ? 'Item ID cannot be changed' : hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              fillColor: readOnly
                  ? (isDark ? Colors.white10 : Colors.grey[300])
                  : AppStyles.getInputBg(isDark),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    final settings = context.read<SettingsProvider>();
    final isDark = settings.isDarkMode;

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
                Text(
                  '|',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 100, // ID Column
                  child: Text(
                    'Item ID',
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                Text(
                  '|',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Product Name',
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                Text(
                  '|',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    'Original Price',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                Text(
                  '|',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    'Selling Price',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                Text(
                  '|',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Profit',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                Text(
                  '|',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
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
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final profit = p.sellingPrice - p.originalPrice;
                      final isHovered = _hoveredIndex == index;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 50, child: Text('${index + 1}')),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      p.itemName,
                                      style: TextStyle(
                                        color: AppStyles.getTextColor(isDark),
                                      ),
                                    ),
                                    if (p.quantity != null)
                                      Text(
                                        'Qty: ${p.quantity}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  '${settings.currencySymbol}${p.originalPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppStyles.getTextColor(isDark),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  '${settings.currencySymbol}${p.sellingPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppStyles.getTextColor(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '${settings.currencySymbol}${profit.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
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
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _deleteProduct(p.itemId),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
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
