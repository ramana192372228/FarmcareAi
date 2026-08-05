import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _shopId = 'SHOP1234';
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String _sortBy = 'name'; // 'name', 'price_asc', 'price_desc', 'stock'

  final List<String> _categories = ['ALL', 'SEEDS', 'FERTILIZER', 'PESTICIDES', 'EQUIPMENT', 'CROP_CARE', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _initializeShopAndInventory();
  }

  Future<void> _initializeShopAndInventory() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      setState(() {
        _shopId = phone;
      });
    }

    final service = FirestoreService();
    service.getShopProductsStream(_shopId).first.then((items) async {
      if (items.isEmpty) {
        final initialItems = [
          {
            'name': 'Hybrid Cotton Seeds H-4',
            'category': 'SEEDS',
            'brand': 'Mahyco',
            'description': 'High yield disease-resistant hybrid cotton seeds.',
            'imageUrl': 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?w=500',
            'stock': 120,
            'unit': '450g Pack',
            'buyingPrice': 280.0,
            'price': 350.0,
            'discount': 5.0,
            'supplier': 'Mahyco Seeds Ltd.',
            'expiryDate': '2027-12-31',
          },
          {
            'name': 'Basmati Rice Seeds Super-1',
            'category': 'SEEDS',
            'brand': 'Kaveri Seeds',
            'description': 'Premium long-grain aromatic basmati paddy seeds.',
            'imageUrl': '',
            'stock': 8,
            'unit': '5kg Bag',
            'buyingPrice': 750.0,
            'price': 890.0,
            'discount': 0.0,
            'supplier': 'Kaveri Agri Corp',
            'expiryDate': '2026-11-30',
          },
          {
            'name': 'Organic Neem Cake Fertilizer',
            'category': 'FERTILIZER',
            'brand': 'NeemCare',
            'description': 'Pure cold-pressed organic neem cake for soil conditioning.',
            'imageUrl': '',
            'stock': 45,
            'unit': '10kg Bag',
            'buyingPrice': 320.0,
            'price': 420.0,
            'discount': 8.0,
            'supplier': 'EcoAgri Organic',
            'expiryDate': '2028-06-30',
          },
          {
            'name': '16L Manual Knapsack Sprayer',
            'category': 'EQUIPMENT',
            'brand': 'Aspee',
            'description': 'Heavy-duty brass nozzle high-pressure garden sprayer.',
            'imageUrl': '',
            'stock': 0,
            'unit': '1 unit',
            'buyingPrice': 950.0,
            'price': 1200.0,
            'discount': 10.0,
            'supplier': 'Aspee Equipment',
          },
        ];
        for (var item in initialItems) {
          final docId = 'prod_${_shopId}_${DateTime.now().microsecondsSinceEpoch}_${item['name'].hashCode}';
          await service.saveProduct(docId, {
            ...item,
            'shopId': _shopId,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }

  void _showAddEditProductModal([Map<String, dynamic>? product]) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    String category = product?['category'] ?? 'SEEDS';
    final brandCtrl = TextEditingController(text: product?['brand'] ?? '');
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final imageCtrl = TextEditingController(text: product?['imageUrl'] ?? '');
    final stockCtrl = TextEditingController(text: (product?['stock'] ?? 0).toString());
    final unitCtrl = TextEditingController(text: product?['unit'] ?? 'Pack');
    final buyingPriceCtrl = TextEditingController(text: (product?['buyingPrice'] ?? product?['price'] ?? 0.0).toString());
    final sellingPriceCtrl = TextEditingController(text: (product?['price'] ?? 0.0).toString());
    final discountCtrl = TextEditingController(text: (product?['discount'] ?? 0.0).toString());
    final expiryCtrl = TextEditingController(text: product?['expiryDate'] ?? '');
    final supplierCtrl = TextEditingController(text: product?['supplier'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Edit Product Inventory' : 'Add New Product', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name*')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _categories.contains(category) ? category : 'SEEDS',
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.where((c) => c != 'ALL').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setModalState(() => category = val!),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g. 5kg Bag)'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: buyingPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buying Price (₹)'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: sellingPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price (₹)*'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity*'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount %'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: expiryCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL (Optional)')),
                  const SizedBox(height: 10),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Product Description')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || sellingPriceCtrl.text.trim().isEmpty) return;

                final productId = product?['id'] ?? 'prod_${_shopId}_${DateTime.now().millisecondsSinceEpoch}';
                final data = {
                  'shopId': _shopId,
                  'name': nameCtrl.text.trim(),
                  'category': category,
                  'brand': brandCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'imageUrl': imageCtrl.text.trim(),
                  'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                  'unit': unitCtrl.text.trim(),
                  'buyingPrice': double.tryParse(buyingPriceCtrl.text.trim()) ?? 0.0,
                  'price': double.tryParse(sellingPriceCtrl.text.trim()) ?? 0.0,
                  'discount': double.tryParse(discountCtrl.text.trim()) ?? 0.0,
                  'supplier': supplierCtrl.text.trim(),
                  'expiryDate': expiryCtrl.text.trim(),
                };

                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                await FirestoreService().saveProduct(productId, data);
                if (mounted) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Product updated successfully!' : 'New product added!'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('SAVE PRODUCT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(String productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to remove "$productName" from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await FirestoreService().deleteProduct(productId);
              if (mounted) {
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Product deleted.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(trans.translate('inventory'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Add Product',
            onPressed: () => _showAddEditProductModal(),
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
                        hintText: 'Search product, brand...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Name', style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'price_asc', child: Text('Price ↑', style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'price_desc', child: Text('Price ↓', style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'stock', child: Text('Stock', style: TextStyle(fontSize: 11))),
                        ],
                        onChanged: (val) => setState(() => _sortBy = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Stream List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getShopProductsStream(_shopId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('No products in inventory.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditProductModal(),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('ADD FIRST PRODUCT', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      );
                    }

                    var items = snapshot.data!;

                    // Filter
                    items = items.where((p) {
                      final name = (p['name'] ?? '').toString().toLowerCase();
                      final brand = (p['brand'] ?? '').toString().toLowerCase();
                      final cat = (p['category'] ?? '').toString();
                      final matchesQ = name.contains(_searchQuery.toLowerCase()) || brand.contains(_searchQuery.toLowerCase());
                      final matchesC = _selectedCategory == 'ALL' || cat == _selectedCategory;
                      return matchesQ && matchesC;
                    }).toList();

                    // Sort
                    items.sort((a, b) {
                      if (_sortBy == 'price_asc') {
                        return ((a['price'] as num? ?? 0.0)).compareTo((b['price'] as num? ?? 0.0));
                      } else if (_sortBy == 'price_desc') {
                        return ((b['price'] as num? ?? 0.0)).compareTo((a['price'] as num? ?? 0.0));
                      } else if (_sortBy == 'stock') {
                        return ((b['stock'] as num? ?? 0)).compareTo((a['stock'] as num? ?? 0));
                      } else {
                        return ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String);
                      }
                    });

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final stock = item['stock'] as int? ?? 0;
                        final price = (item['price'] as num? ?? 0.0).toDouble();
                        final discount = (item['discount'] as num? ?? 0.0).toDouble();

                        // Stock Status Badge
                        String statusLabel = 'In Stock';
                        Color statusColor = AppTheme.primaryGreen;
                        if (stock <= 0) {
                          statusLabel = 'Out of Stock';
                          statusColor = Colors.redAccent;
                        } else if (stock <= 10) {
                          statusLabel = 'Low Stock ($stock left)';
                          statusColor = AppTheme.accentGold;
                        }

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item['category'] as String? ?? 'SEEDS',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                      onPressed: () => _showAddEditProductModal(item),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => _confirmDeleteProduct(item['id'], item['name']),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(item['name'] as String? ?? 'Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                if (item['brand'] != null && (item['brand'] as String).isNotEmpty)
                                  Text('Brand: ${item['brand']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '₹${price.toStringAsFixed(2)} / ${item['unit'] ?? 'Pack'}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                        ),
                                        if (discount > 0)
                                          Text('$discount% OFF', style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Text(
                                      'Stock: $stock units',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: stock <= 10 ? Colors.redAccent : Colors.black87),
                                    ),
                                  ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditProductModal(),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD PRODUCT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
