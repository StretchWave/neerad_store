class Product {
  final int? id;
  final String itemId;
  final String itemName;
  final double originalPrice;
  final double sellingPrice;
  final int? quantity;
  final DateTime? lastUpdated;

  Product({
    this.id,
    required this.itemId,
    required this.itemName,
    required this.originalPrice,
    required this.sellingPrice,
    this.quantity,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'original_price': originalPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      // last_updated is usually handled by DB on insert/update, but providing it optionally
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: int.tryParse(map['id']?.toString() ?? ''),
      itemId: map['item_id']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      originalPrice:
          double.tryParse(map['original_price']?.toString() ?? '0') ?? 0.0,
      sellingPrice:
          double.tryParse(map['selling_price']?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(map['quantity']?.toString() ?? ''),
      lastUpdated: DateTime.tryParse(map['last_updated']?.toString() ?? ''),
    );
  }
}
