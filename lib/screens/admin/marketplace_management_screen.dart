import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class MarketplaceManagementScreen extends StatefulWidget {
  const MarketplaceManagementScreen({super.key});

  @override
  State<MarketplaceManagementScreen> createState() => _MarketplaceManagementScreenState();
}

class _MarketplaceManagementScreenState extends State<MarketplaceManagementScreen> {
  String _searchQuery = '';
  String _categoryFilter = 'ALL';

  final List<String> _categories = [
    'ALL',
    'Seeds',
    'Fertilizers',
    'Pesticides',
    'Tools & Machinery',
    'Irrigation',
    'Organic Care',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Marketplace & Catalog Governance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search & Category Filters
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search seed, pesticide, shop...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoryFilter,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
                        onChanged: (val) => setState(() => _categoryFilter = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Catalog Stream
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getShopProductsStream('ALL'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                    }

                    var products = snapshot.data ?? [];

                    // Seed demo products if empty
                    if (products.isEmpty) {
                      products = [
                        {
                          'id': 'p1',
                          'name': 'Hybrid Cotton Seeds H-4',
                          'category': 'Seeds',
                          'brand': 'Mahyco',
                          'price': 850.0,
                          'stock': 120,
                          'shopId': 'SHOP101',
                          'isFeatured': true,
                        },
                        {
                          'id': 'p2',
                          'name': 'Organic Neem Cake Bio-Fertilizer',
                          'category': 'Fertilizers',
                          'brand': 'NeemCare',
                          'price': 420.0,
                          'stock': 45,
                          'shopId': 'SHOP102',
                          'isFeatured': false,
                        },
                        {
                          'id': 'p3',
                          'name': 'Monocrotophos Insecticide 36% SL',
                          'category': 'Pesticides',
                          'brand': 'Syngenta',
                          'price': 640.0,
                          'stock': 15,
                          'shopId': 'SHOP101',
                          'isFeatured': true,
                        },
                      ];
                    }

                    // Filter
                    products = products.where((p) {
                      final name = (p['name'] ?? '').toString().toLowerCase();
                      final brand = (p['brand'] ?? '').toString().toLowerCase();
                      final cat = (p['category'] ?? '').toString();
                      final q = _searchQuery.toLowerCase();

                      final matchesSearch = name.contains(q) || brand.contains(q);
                      final matchesCat = _categoryFilter == 'ALL' || cat == _categoryFilter;
                      return matchesSearch && matchesCat;
                    }).toList();

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        final isFeatured = p['isFeatured'] ?? false;

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryGreen),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(p['name'] as String? ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                if (isFeatured)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('FEATURED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                                  ),
                              ],
                            ),
                            subtitle: Text('Category: ${p['category']} • Price: ₹${p['price']} • Stock: ${p['stock']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(isFeatured ? Icons.star_rounded : Icons.star_border_rounded, color: AppTheme.accentGold),
                                  onPressed: () async {
                                    await FirestoreService().saveProduct(p['id'], {'isFeatured': !isFeatured});
                                  },
                                  tooltip: isFeatured ? 'Unfeature' : 'Feature Product',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: () => _deleteProduct(p['id'], p['name'] ?? 'Product'),
                                  tooltip: 'Delete Product',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Future<void> _deleteProduct(String productId, String name) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Marketplace Item?'),
        content: Text('Are you sure you want to remove "$name" from the platform catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteProduct(productId);
              await FirestoreService().logAuditEvent(
                userId: 'ADMIN',
                action: 'Deleted Product',
                category: 'MARKETPLACE',
                details: 'Deleted product $name ($productId)',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
