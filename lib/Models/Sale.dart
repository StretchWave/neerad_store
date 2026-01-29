class Sale {
  final int? id;
  final String itemId;
  final String itemName;
  final int quantity;
  final double discount;
  final double profit;
  final double totalPrice;
  final DateTime? saleDate;
  final String transactionId;

  Sale({
    this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.discount,
    required this.profit,
    required this.totalPrice,
    this.saleDate,
    required this.transactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'discount': discount,
      'profit': profit,
      'total_price': totalPrice,
      'sale_date': saleDate?.toIso8601String(),
      'transaction_id': transactionId,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: int.tryParse(map['id']?.toString() ?? ''),
      itemId: map['item_id']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      discount: double.tryParse(map['discount']?.toString() ?? '0') ?? 0.0,
      profit: double.tryParse(map['profit']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(map['total_price']?.toString() ?? '0') ?? 0.0,
      saleDate: map['sale_date'] != null
          ? DateTime.tryParse(map['sale_date'].toString())
          : null,
      transactionId: map['transaction_id']?.toString() ?? '',
    );
  }
}
