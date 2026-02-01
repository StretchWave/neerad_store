import 'package:mysql_client/mysql_client.dart';
import 'package:neerad_store/Models/Product.dart';
import 'package:neerad_store/Models/Sale.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  MySQLConnection? _connection;

  Future<MySQLConnection> get connection async {
    if (_connection != null && _connection!.connected) return _connection!;

    _connection = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 3306,
      userName: 'root',
      password: '1234',
      databaseName: 'neeradstore',
    );

    try {
      await _connection!.connect();
      await _initTables();
      return _connection!;
    } catch (e) {
      print('Database connection error: $e');
      rethrow;
    }
  }

  Future<void> _initTables() async {
    final conn = _connection!;

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        item_id VARCHAR(255) UNIQUE NOT NULL,
        item_name VARCHAR(255) NOT NULL,
        original_price DECIMAL(10, 2) NOT NULL,
        selling_price DECIMAL(10, 2) NOT NULL,
        selling_price DECIMAL(10, 2) NOT NULL,
        quantity INT DEFAULT NULL,
        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Migration to add quantity column if it doesn't exist
    try {
      await conn.execute('SELECT quantity FROM products LIMIT 1');
    } catch (e) {
      await conn.execute(
        'ALTER TABLE products ADD COLUMN quantity INT DEFAULT NULL',
      );
    }

    // Migration to add last_updated column if it doesn't exist
    try {
      await conn.execute('SELECT last_updated FROM products LIMIT 1');
    } catch (e) {
      await conn.execute(
        'ALTER TABLE products ADD COLUMN last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
      );
    }

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INT AUTO_INCREMENT PRIMARY KEY,
        transaction_id VARCHAR(255) NOT NULL,
        item_id VARCHAR(255) NOT NULL,
        item_name VARCHAR(255) NOT NULL,
        quantity INT NOT NULL,
        discount DECIMAL(10, 2) DEFAULT 0.00,
        profit DECIMAL(10, 2) NOT NULL,
        total_price DECIMAL(10, 2) NOT NULL,
        sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key_name VARCHAR(255) PRIMARY KEY,
        key_value TEXT
      )
    ''');
  }

  // Product Operations
  Future<void> addProduct(Product product) async {
    final conn = await connection;
    await conn.execute(
      'INSERT INTO products (item_id, item_name, original_price, selling_price, quantity, last_updated) VALUES (:id, :name, :orig, :sell, :qty, NOW())',
      {
        'id': product.itemId,
        'name': product.itemName,
        'orig': product.originalPrice,
        'sell': product.sellingPrice,
        'qty': product.quantity,
      },
    );
  }

  Future<void> updateProduct(Product product) async {
    final conn = await connection;
    await conn.execute(
      'UPDATE products SET item_name = :name, original_price = :orig, selling_price = :sell, quantity = :qty, last_updated = NOW() WHERE item_id = :id',
      {
        'name': product.itemName,
        'orig': product.originalPrice,
        'sell': product.sellingPrice,
        'qty': product.quantity,
        'id': product.itemId,
      },
    );
  }

  Future<void> deleteProduct(String itemId) async {
    final conn = await connection;
    await conn.execute('DELETE FROM products WHERE item_id = :id', {
      'id': itemId,
    });
  }

  Future<String> getNextAvailableId() async {
    final conn = await connection;
    // Get all item_ids that are integers, sorted
    final results = await conn.execute(
      'SELECT item_id FROM products WHERE item_id REGEXP "^[0-9]+\$" ORDER BY CAST(item_id AS UNSIGNED) ASC',
    );

    int nextId = 0;
    for (final row in results.rows) {
      final currentId = int.tryParse(row.assoc()['item_id'] ?? '-1') ?? -1;
      if (currentId == nextId) {
        nextId++;
      } else if (currentId > nextId) {
        // Found a gap or end of sequence for this specific simple logic
        return nextId.toString();
      }
    }
    return nextId.toString();
  }

  Future<void> deleteSalesBefore(DateTime date) async {
    final conn = await connection;
    final dateStr = date.toIso8601String().split('T')[0];
    await conn.execute('DELETE FROM sales WHERE sale_date < :date', {
      'date': dateStr,
    });
  }

  Future<List<Product>> getAllProducts() async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM products ORDER BY last_updated DESC',
    );
    return results.rows.map((row) => Product.fromMap(row.assoc())).toList();
  }

  Future<List<Product>> searchSuggestions(String query) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM products WHERE item_name LIKE :query LIMIT 50',
      {'query': '%$query%'},
    );
    return results.rows.map((row) => Product.fromMap(row.assoc())).toList();
  }

  Future<Product?> findProduct(String query) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM products WHERE item_id = :query OR item_name = :query LIMIT 1',
      {'query': query},
    );
    if (results.rows.isEmpty) return null;
    return Product.fromMap(results.rows.first.assoc());
  }

  // Sale Operations
  Future<void> addSale(Sale sale) async {
    final conn = await connection;
    await conn.execute(
      'INSERT INTO sales (transaction_id, item_id, item_name, quantity, discount, profit, total_price) VALUES (:tid, :iid, :name, :qty, :disc, :prof, :total)',
      {
        'tid': sale.transactionId,
        'iid': sale.itemId,
        'name': sale.itemName,
        'qty': sale.quantity,
        'disc': sale.discount,
        'prof': sale.profit,
        'total': sale.totalPrice,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionGroups() async {
    final conn = await connection;
    final results = await conn.execute('''
      SELECT transaction_id, MAX(sale_date) as sale_date, SUM(total_price) as total_amount, SUM(profit) as total_profit
      FROM sales 
      GROUP BY transaction_id 
      ORDER BY sale_date DESC
    ''');
    return results.rows.map((row) {
      final map = row.assoc();
      return {
        'transaction_id': map['transaction_id'],
        'sale_date':
            DateTime.tryParse(map['sale_date'] ?? '') ?? DateTime.now(),
        'total_amount': double.tryParse(map['total_amount'] ?? '0') ?? 0.0,
        'total_profit': double.tryParse(map['total_profit'] ?? '0') ?? 0.0,
      };
    }).toList();
  }

  Future<List<Sale>> getSalesByTransactionId(String transactionId) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT * FROM sales WHERE transaction_id = :id',
      {'id': transactionId},
    );
    return results.rows.map((row) => Sale.fromMap(row.assoc())).toList();
  }

  Future<Map<String, dynamic>> getStatistics(
    DateTime start,
    DateTime end,
  ) async {
    final conn = await connection;
    // Format dates for SQL
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final results = await conn.execute(
      '''
      SELECT 
        SUM(profit) as total_profit, 
        SUM(total_price) as total_amount,
        SUM(quantity) as total_items,
        COUNT(DISTINCT transaction_id) as total_sales
      FROM sales 
      WHERE DATE(sale_date) BETWEEN :start AND :end
    ''',
      {'start': startStr, 'end': endStr},
    );

    if (results.rows.isEmpty) {
      return {
        'total_profit': 0.0,
        'total_amount': 0.0,
        'total_items': 0,
        'total_sales': 0,
      };
    }

    final fields = results.rows.first.assoc();
    final totalSales = int.tryParse(fields['total_sales'] ?? '0') ?? 0;

    if (totalSales == 0) {
      return {
        'total_profit': 0.0,
        'total_amount': 0.0,
        'total_items': 0,
        'total_sales': 0,
      };
    }

    return {
      'total_profit': double.tryParse(fields['total_profit'] ?? '0') ?? 0.0,
      'total_amount': double.tryParse(fields['total_amount'] ?? '0') ?? 0.0,
      'total_items': int.tryParse(fields['total_items'] ?? '0') ?? 0,
      'total_sales': totalSales,
    };
  }

  Future<double> getDailyProfit() async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT SUM(profit) as daily_profit FROM sales WHERE DATE(sale_date) = CURDATE()',
    );
    if (results.rows.isEmpty) return 0.0;
    final map = results.rows.first.assoc();
    return double.tryParse(map['daily_profit'] ?? '0') ?? 0.0;
  }

  // Settings Operations
  Future<void> setSetting(String key, String value) async {
    final conn = await connection;
    await conn.execute(
      'INSERT INTO settings (key_name, key_value) VALUES (:key, :val) ON DUPLICATE KEY UPDATE key_value = :val2',
      {'key': key, 'val': value, 'val2': value},
    );
  }

  Future<String?> getSetting(String key) async {
    final conn = await connection;
    final results = await conn.execute(
      'SELECT key_value FROM settings WHERE key_name = :key',
      {'key': key},
    );
    if (results.rows.isEmpty) return null;
    return results.rows.first.assoc()['key_value'];
  }
}
