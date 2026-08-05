import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ShopCustomersScreen extends StatefulWidget {
  const ShopCustomersScreen({super.key});

  @override
  State<ShopCustomersScreen> createState() => _ShopCustomersScreenState();
}

class _ShopCustomersScreenState extends State<ShopCustomersScreen> {
  String _shopId = 'SHOP1234';
  String _searchQuery = '';
  String _sortBy = 'spending'; // 'spending', 'orders', 'recent', 'name'
  bool _isLoading = true;
  List<CustomerModel> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      _shopId = phone;
    }
    await _aggregateCustomers();
  }

  Future<void> _aggregateCustomers() async {
    setState(() => _isLoading = true);
    try {
      final service = FirestoreService();
      
      // Fetch orders, purchases, and machinery requests
      final orders = await service.getShopOrdersStream(_shopId).first;
      final purchases = await service.getShopPurchasesStream(_shopId).first;
      final machineryReqs = await service.getShopMachineryRequestsStream().first;

      final Map<String, CustomerModel> customerMap = {};

      // 1. Process Orders
      for (final order in orders) {
        final farmerId = order['farmerId'] as String? ?? 'FAR_UNKNOWN';
        final farmerName = order['farmerName'] as String? ?? 'Farmer ($farmerId)';
        final farmerPhone = order['farmerPhone'] as String? ?? farmerId;
        final village = order['village'] as String? ?? order['address'] as String? ?? 'Local Village';
        final totalAmount = (order['totalAmount'] as num? ?? 0.0).toDouble();
        final orderDateStr = order['createdAt'];

        final customer = customerMap.putIfAbsent(
          farmerPhone,
          () => CustomerModel(
            id: farmerId,
            name: farmerName,
            phone: farmerPhone,
            village: village,
          ),
        );

        customer.totalOrders += 1;
        customer.totalSpending += totalAmount;
        
        // Track items
        final items = order['items'] as List? ?? [];
        for (var item in items) {
          final pName = item['productName'] as String? ?? 'Product';
          customer.purchasedItemsCount[pName] = (customer.purchasedItemsCount[pName] ?? 0) + 1;
        }

        if (orderDateStr != null) {
          final time = _parseDate(orderDateStr);
          if (customer.lastActivity == null || time.isAfter(customer.lastActivity!)) {
            customer.lastActivity = time;
          }
        }
      }

      // 2. Process Procurement Purchases
      for (final pur in purchases) {
        final farmerId = pur['farmerId'] as String? ?? 'FAR_UNKNOWN';
        final farmerName = pur['farmerName'] as String? ?? 'Farmer ($farmerId)';
        final totalAmount = (pur['totalAmount'] as num? ?? 0.0).toDouble();
        final purDateStr = pur['createdAt'];

        final customer = customerMap.putIfAbsent(
          farmerId,
          () => CustomerModel(
            id: farmerId,
            name: farmerName,
            phone: farmerId,
            village: 'Local Village',
          ),
        );

        customer.totalCropProcurements += 1;
        customer.totalProcurementValue += totalAmount;

        if (purDateStr != null) {
          final time = _parseDate(purDateStr);
          if (customer.lastActivity == null || time.isAfter(customer.lastActivity!)) {
            customer.lastActivity = time;
          }
        }
      }

      // 3. Process Machinery Rentals
      for (final req in machineryReqs) {
        final farmerId = req['farmerId'] as String? ?? 'FAR_UNKNOWN';
        final farmerName = req['farmerName'] as String? ?? 'Farmer ($farmerId)';
        final reqDateStr = req['createdAt'];

        final customer = customerMap.putIfAbsent(
          farmerId,
          () => CustomerModel(
            id: farmerId,
            name: farmerName,
            phone: farmerId,
            village: 'Local Village',
          ),
        );

        customer.totalMachineryRentals += 1;

        if (reqDateStr != null) {
          final time = _parseDate(reqDateStr);
          if (customer.lastActivity == null || time.isAfter(customer.lastActivity!)) {
            customer.lastActivity = time;
          }
        }
      }

      // Pre-seed demo customers if empty for instant rich UI demonstration
      if (customerMap.isEmpty) {
        customerMap['9876543210'] = CustomerModel(
          id: 'FAR1234',
          name: 'Rajesh Kumar',
          phone: '9876543210',
          village: 'Ramapuram',
          totalOrders: 6,
          totalSpending: 14500,
          totalCropProcurements: 2,
          totalProcurementValue: 28000,
          totalMachineryRentals: 1,
          lastActivity: DateTime.now().subtract(const Duration(hours: 4)),
          purchasedItemsCount: {'Hybrid Cotton Seeds H-4': 4, 'Organic Neem Cake': 2},
        );

        customerMap['9848022334'] = CustomerModel(
          id: 'FAR5678',
          name: 'Venkateswarlu Naidu',
          phone: '9848022334',
          village: 'Tadikonda',
          totalOrders: 4,
          totalSpending: 9200,
          totalCropProcurements: 1,
          totalProcurementValue: 18500,
          totalMachineryRentals: 2,
          lastActivity: DateTime.now().subtract(const Duration(days: 1)),
          purchasedItemsCount: {'Basmati Rice Seeds Super-1': 3},
        );

        customerMap['9912345678'] = CustomerModel(
          id: 'FAR9900',
          name: 'Kondal Rao',
          phone: '9912345678',
          village: 'Mangalagiri',
          totalOrders: 3,
          totalSpending: 6400,
          lastActivity: DateTime.now().subtract(const Duration(days: 3)),
          purchasedItemsCount: {'16L Knapsack Sprayer': 1},
        );
      }

      _customers = customerMap.values.toList();
    } catch (e) {
      debugPrint('[SHOP_CUSTOMERS] Error loading customer database: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _parseDate(dynamic val) {
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  List<CustomerModel> get _filteredCustomers {
    var list = _customers.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.village.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      if (_sortBy == 'spending') {
        return b.totalSpending.compareTo(a.totalSpending);
      } else if (_sortBy == 'orders') {
        return b.totalOrders.compareTo(a.totalOrders);
      } else if (_sortBy == 'recent') {
        final aTime = a.lastActivity ?? DateTime(2000);
        final bTime = b.lastActivity ?? DateTime(2000);
        return bTime.compareTo(aTime);
      } else {
        return a.name.compareTo(b.name);
      }
    });

    return list;
  }

  void _showCustomerDetailModal(CustomerModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('📞 ${c.phone} • 📍 ${c.village}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total Orders', '${c.totalOrders}', Icons.shopping_bag_outlined, Colors.blue),
                _buildStatBox('Total Spent', '₹${c.totalSpending.toStringAsFixed(0)}', Icons.payments_outlined, AppTheme.primaryGreen),
                _buildStatBox('Crop Sold', '₹${c.totalProcurementValue.toStringAsFixed(0)}', Icons.scale_outlined, AppTheme.accentGold),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Favorite Products Purchased',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            c.purchasedItemsCount.isEmpty
                ? const Text('No store purchases recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 13))
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: c.purchasedItemsCount.entries.map((entry) {
                      return Chip(
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        avatar: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen,
                          child: Text('${entry.value}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                        label: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String val, IconData icon, Color col) {
    return Column(
      children: [
        Icon(icon, color: col, size: 22),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: col)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredCustomers;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Customer Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _aggregateCustomers,
            tooltip: 'Refresh Customers',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Search & Filter Header Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search customer name, phone, village...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'spending', child: Text('Sort: Spending')),
                          DropdownMenuItem(value: 'orders', child: Text('Sort: Orders')),
                          DropdownMenuItem(value: 'recent', child: Text('Sort: Recent')),
                          DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _sortBy = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                const Text('No Customers Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Farmers placing orders or selling crops will appear here.', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: list.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final c = list[index];
                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  onTap: () => _showCustomerDetailModal(c),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                                    child: Text(
                                      c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                    ),
                                  ),
                                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('📞 ${c.phone} • 📍 ${c.village}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _buildBadge('Orders: ${c.totalOrders}', Colors.blue),
                                          const SizedBox(width: 6),
                                          _buildBadge('Rentals: ${c.totalMachineryRentals}', AppTheme.accentGold),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${c.totalSpending.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text('Total Revenue', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
      ),
    );
  }

  Widget _buildBadge(String label, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String village;
  int totalOrders;
  double totalSpending;
  int totalCropProcurements;
  double totalProcurementValue;
  int totalMachineryRentals;
  DateTime? lastActivity;
  Map<String, int> purchasedItemsCount;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.village,
    this.totalOrders = 0,
    this.totalSpending = 0.0,
    this.totalCropProcurements = 0,
    this.totalProcurementValue = 0.0,
    this.totalMachineryRentals = 0,
    this.lastActivity,
    Map<String, int>? purchasedItemsCount,
  }) : purchasedItemsCount = purchasedItemsCount ?? {};
}
