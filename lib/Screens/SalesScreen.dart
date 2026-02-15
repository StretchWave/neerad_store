import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neerad_store/Providers/SettingsProvider.dart';
import 'package:intl/intl.dart';
import 'package:neerad_store/Services/DatabaseService.dart';
import 'package:neerad_store/Styles/AppStyles.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DatabaseService _db = DatabaseService();

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
              Text(
                'Sales History:',
                style: AppStyles.getScreenTitleStyle(isDark),
              ),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    tooltip: 'Clear history before this month',
                    onPressed: _deleteOldSales,
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showStatistics,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Statistics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _db.getTransactionGroups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return const Center(child: Text('No sales found.'));
                }

                return _buildSalesTable(groups);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable(List<Map<String, dynamic>> groups) {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            color: AppStyles.getTableHeaderBg(isDark),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    'Transaction ID',
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Date & Time',
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    'Total Amount',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    'Profit',
                    textAlign: TextAlign.center,
                    style: AppStyles.getTableHeaderStyle(isDark),
                  ),
                ),
                const SizedBox(width: 80), // For Action button
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return InkWell(
                  onTap: () => _showSaleDetails(group['transaction_id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
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
                          width: 200,
                          child: Text(
                            group['transaction_id'],
                            style: TextStyle(
                              color: AppStyles.getTextColor(isDark),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'dd-MM-yyyy  hh:mm a',
                            ).format(group['sale_date']),
                            style: TextStyle(
                              color: AppStyles.getTextColor(isDark),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Text(
                            '₹${group['total_amount'].toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppStyles.getTextColor(isDark),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Text(
                            '₹${group['total_profit'].toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                        const SizedBox(
                          width: 80,
                          child: Icon(Icons.chevron_right, color: Colors.grey),
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

  void _showSaleDetails(String transactionId) async {
    final sales = await _db.getSalesByTransactionId(transactionId);
    if (!mounted) return;

    // Use current state for isDark in this context
    final isDark = context.read<SettingsProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.getDialogBgColor(isDark),
        title: Text(
          'Sale Details: $transactionId',
          style: AppStyles.getDialogTitleStyle(isDark),
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Item',
                      style: AppStyles.getDialogHeaderStyle(isDark),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Qty',
                      style: AppStyles.getDialogHeaderStyle(isDark),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Profit',
                      style: AppStyles.getDialogHeaderStyle(isDark),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Total',
                      style: AppStyles.getDialogHeaderStyle(isDark),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Divider(color: AppStyles.getDividerColor(isDark)),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...sales.map(
                        (sale) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  sale.itemName,
                                  style: AppStyles.getDialogTextStyle(isDark),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  sale.quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: AppStyles.getDialogTextStyle(isDark),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  sale.profit.toStringAsFixed(2),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  sale.totalPrice.toStringAsFixed(2),
                                  textAlign: TextAlign.center,
                                  style: AppStyles.getDialogTextStyle(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Summary:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppStyles.getTextColor(isDark),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final totalProfit = sales.fold(
                        0.0,
                        (sum, item) => sum + item.profit,
                      );
                      final totalPrice = sales.fold(
                        0.0,
                        (sum, item) => sum + item.totalPrice,
                      );
                      final totalOriginal = totalPrice - totalProfit;

                      return Text(
                        'P: ${totalProfit.toStringAsFixed(2)} | '
                        'Original: ${totalOriginal.toStringAsFixed(2)} | '
                        'Total: ${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppStyles.getTextColor(isDark),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() async {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (pickedRange != null) {
      final stats = await _db.getStatistics(pickedRange.start, pickedRange.end);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppStyles.getDialogBgColor(isDark),
          title: Text(
            'Statistics (${DateFormat('MMMd').format(pickedRange.start)} - ${DateFormat('MMMd').format(pickedRange.end)})',
            style: AppStyles.getDialogTitleStyle(isDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow(
                'Total Profit:',
                '₹${stats['total_profit'].toStringAsFixed(2)}',
                Colors.green,
                isDark,
              ),
              _buildStatRow(
                'Total Amount:',
                '₹${stats['total_amount'].toStringAsFixed(2)}',
                AppStyles.getTextColor(isDark),
                isDark,
              ),
              _buildStatRow(
                'Total Items Sold:',
                '${stats['total_items']}',
                Colors.blue,
                isDark,
              ),
              _buildStatRow(
                'Total Sales:',
                '${stats['total_sales']}',
                Colors.orange,
                isDark,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteOldSales() async {
    final isDark = context.read<SettingsProvider>().isDarkMode;
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.getDialogBgColor(isDark),
        title: Text(
          'Delete Old History?',
          style: AppStyles.getDialogTitleStyle(isDark),
        ),
        content: Text(
          'This will delete all sales records before ${DateFormat('MMMM d, yyyy').format(firstDayOfCurrentMonth)}.\n\nThis action cannot be undone.',
          style: AppStyles.getDialogTextStyle(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteSalesBefore(firstDayOfCurrentMonth);
        setState(() {}); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Old sales data deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildStatRow(String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppStyles.getTextColor(isDark),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
