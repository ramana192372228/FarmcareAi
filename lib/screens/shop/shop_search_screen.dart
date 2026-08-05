import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'inventory_screen.dart';
import 'orders_screen.dart';
import 'shop_machinery_screen.dart';
import 'crop_purchases_screen.dart';

class ShopSearchScreen extends StatefulWidget {
  const ShopSearchScreen({super.key});

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _shopId = 'SHOP1234';
  bool _isSearching = false;

  List<Map<String, dynamic>> _matchingProducts = [];
  List<Map<String, dynamic>> _matchingOrders = [];
  List<Map<String, dynamic>> _matchingMachinery = [];
  List<Map<String, dynamic>> _matchingProcurement = [];

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  Future<void> _loadShopId() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      _shopId = phone;
    }
  }

  void _onSearchChanged(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _matchingProducts.clear();
        _matchingOrders.clear();
        _matchingMachinery.clear();
        _matchingProcurement.clear();
      });
      return;
    }

    setState(() => _isSearching = true);
    final service = FirestoreService();

    final products = await service.getShopProductsStream(_shopId).first;
    final orders = await service.getShopOrdersStream(_shopId).first;
    final machinery = await service.getShopMachineryRequestsStream().first;
    final cropOffers = await service.getCropOffersStream().first;

    if (mounted) {
      setState(() {
        _matchingProducts = products.where((p) {
          final name = (p['name'] ?? '').toString().toLowerCase();
          final cat = (p['category'] ?? '').toString().toLowerCase();
          final brand = (p['brand'] ?? '').toString().toLowerCase();
          return name.contains(q) || cat.contains(q) || brand.contains(q);
        }).toList();

        _matchingOrders = orders.where((o) {
          final id = (o['orderId'] ?? '').toString().toLowerCase();
          final farmer = (o['farmerName'] ?? '').toString().toLowerCase();
          final status = (o['status'] ?? '').toString().toLowerCase();
          return id.contains(q) || farmer.contains(q) || status.contains(q);
        }).toList();

        _matchingMachinery = machinery.where((m) {
          final name = (m['machineryName'] ?? '').toString().toLowerCase();
          final farmer = (m['farmerName'] ?? '').toString().toLowerCase();
          final status = (m['status'] ?? '').toString().toLowerCase();
          return name.contains(q) || farmer.contains(q) || status.contains(q);
        }).toList();

        _matchingProcurement = cropOffers.where((c) {
          final crop = (c['crop'] ?? '').toString().toLowerCase();
          final farmer = (c['farmerName'] ?? '').toString().toLowerCase();
          final village = (c['village'] ?? '').toString().toLowerCase();
          return crop.contains(q) || farmer.contains(q) || village.contains(q);
        }).toList();

        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _matchingProducts.isNotEmpty ||
        _matchingOrders.isNotEmpty ||
        _matchingMachinery.isNotEmpty ||
        _matchingProcurement.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search products, orders, customers, machinery...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _isSearching
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : _searchCtrl.text.isEmpty
                ? _buildEmptyState('Type to search across products, orders, machinery & procurement')
                : !hasResults
                    ? _buildEmptyState('No matches found for "${_searchCtrl.text}"')
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (_matchingProducts.isNotEmpty)
                            _buildSection(
                              title: 'Products Inventory (${_matchingProducts.length})',
                              icon: Icons.inventory_2_rounded,
                              color: AppTheme.primaryGreen,
                              onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                              children: _matchingProducts.map((p) => ListTile(
                                leading: const Icon(Icons.inventory_rounded, color: AppTheme.primaryGreen),
                                title: Text(p['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Category: ${p['category']} • Stock: ${p['stock']}'),
                                trailing: Text('₹${p['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                              )).toList(),
                            ),
                          if (_matchingOrders.isNotEmpty)
                            _buildSection(
                              title: 'Orders (${_matchingOrders.length})',
                              icon: Icons.local_shipping_rounded,
                              color: Colors.blue,
                              onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                              children: _matchingOrders.map((o) => ListTile(
                                leading: const Icon(Icons.receipt_long_rounded, color: Colors.blue),
                                title: Text('Order #${(o['orderId'] ?? '').toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Farmer: ${o['farmerName']} • Status: ${o['status']}'),
                                trailing: Text('₹${o['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              )).toList(),
                            ),
                          if (_matchingMachinery.isNotEmpty)
                            _buildSection(
                              title: 'Machinery Rentals (${_matchingMachinery.length})',
                              icon: Icons.agriculture_rounded,
                              color: AppTheme.accentGold,
                              onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopMachineryScreen())),
                              children: _matchingMachinery.map((m) => ListTile(
                                leading: const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.accentGold),
                                title: Text(m['machineryName'] ?? 'Machinery', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Farmer: ${m['farmerName']} • Status: ${m['status']}'),
                              )).toList(),
                            ),
                          if (_matchingProcurement.isNotEmpty)
                            _buildSection(
                              title: 'Crop Procurement Offers (${_matchingProcurement.length})',
                              icon: Icons.scale_rounded,
                              color: Colors.purple,
                              onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropPurchasesScreen())),
                              children: _matchingProcurement.map((c) => ListTile(
                                leading: const Icon(Icons.grass_rounded, color: Colors.purple),
                                title: Text(c['crop'] ?? 'Crop Offer', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Farmer: ${c['farmerName']} • Weight: ${c['weight']} kg'),
                                trailing: Text('₹${c['pricePerKg']}/kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                              )).toList(),
                            ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onViewAll,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                TextButton(onPressed: onViewAll, child: const Text('VIEW ALL')),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
