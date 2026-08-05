import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class AdminGlobalSearchScreen extends StatefulWidget {
  const AdminGlobalSearchScreen({super.key});

  @override
  State<AdminGlobalSearchScreen> createState() => _AdminGlobalSearchScreenState();
}

class _AdminGlobalSearchScreenState extends State<AdminGlobalSearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    final q = query.toLowerCase();
    final List<Map<String, dynamic>> items = [];

    try {
      final service = FirestoreService();

      // Search users
      final users = await service.getAllUsers();
      for (final u in users) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final phone = (u['phone'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        if (name.contains(q) || phone.contains(q) || email.contains(q)) {
          items.add({'type': 'USER', 'title': u['name'] ?? 'User', 'subtitle': 'Role: ${u['role']} • Phone: ${u['phone']}', 'icon': Icons.person_rounded, 'color': Colors.blue});
        }
      }

      // Search products
      final products = await service.getShopProductsStream('ALL').first;
      for (final p in products) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final brand = (p['brand'] ?? '').toString().toLowerCase();
        if (name.contains(q) || brand.contains(q)) {
          items.add({'type': 'PRODUCT', 'title': p['name'] ?? 'Product', 'subtitle': 'Category: ${p['category']} • Price: ₹${p['price']}', 'icon': Icons.inventory_2_rounded, 'color': AppTheme.primaryGreen});
        }
      }

      // Search orders
      final orders = await service.getAllOrders();
      for (final o in orders) {
        final farmer = (o['farmerName'] ?? '').toString().toLowerCase();
        final id = (o['orderId'] ?? '').toString().toLowerCase();
        if (farmer.contains(q) || id.contains(q)) {
          items.add({'type': 'ORDER', 'title': 'Order #${o['orderId']}', 'subtitle': 'Farmer: ${o['farmerName']} • ₹${o['totalAmount']}', 'icon': Icons.shopping_bag_rounded, 'color': AppTheme.accentGold});
        }
      }

      // Search community posts
      final posts = await service.getCommunityPostsStream().first;
      for (final cp in posts) {
        final title = (cp['title'] ?? '').toString().toLowerCase();
        final author = (cp['authorName'] ?? '').toString().toLowerCase();
        if (title.contains(q) || author.contains(q)) {
          items.add({'type': 'COMMUNITY', 'title': cp['title'] ?? 'Post', 'subtitle': 'By: ${cp['authorName']}', 'icon': Icons.forum_rounded, 'color': Colors.purple});
        }
      }
    } catch (e) {
      debugPrint('[GLOBAL_SEARCH] Search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _results = items;
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Admin Global Search', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: _performSearch,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search users, products, orders, forum posts...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  _searchCtrl.text.isEmpty ? 'Type keywords to search across platform collections.' : 'No results found for "${_searchCtrl.text}".',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final res = _results[index];
                              final color = res['color'] as Color? ?? AppTheme.primaryGreen;

                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                                    child: Icon(res['icon'] as IconData, color: color, size: 20),
                                  ),
                                  title: Text(res['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(res['subtitle'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                    child: Text(res['type'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
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
}
