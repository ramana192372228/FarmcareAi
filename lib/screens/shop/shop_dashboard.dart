import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'inventory_screen.dart';
import 'crop_purchases_screen.dart';
import 'orders_screen.dart';
import 'shop_machinery_screen.dart';
import 'shop_customers_screen.dart';
import 'shop_analytics_screen.dart';
import 'shop_notifications_screen.dart';
import 'shop_profile_screen.dart';
import 'shop_search_screen.dart';
import '../../widgets/web_layout_shell.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  String _shopId = 'SHOP1234';

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  Future<void> _loadShopId() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      setState(() {
        _shopId = phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();
    final service = FirestoreService();

    final content = Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Shop Owner Business Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Global Search',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopSearchScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopNotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopProfileScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcoming Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agri Business Management',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Welcome, ${_shopId.toUpperCase()}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Live Inventory, Orders, Rentals & Procurement Operations',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Live Metrics Cards Grid (10 Live Stats)
                const Text(
                  'BUSINESS OVERVIEW',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: service.getShopProductsStream(_shopId),
                  builder: (context, prodSnapshot) {
                    final products = prodSnapshot.data ?? [];
                    final totalProd = products.length;
                    final lowStockCount = products.where((p) => ((p['stock'] as num? ?? 0) <= 10)).length;

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: service.getShopOrdersStream(_shopId),
                      builder: (context, orderSnapshot) {
                        final orders = orderSnapshot.data ?? [];
                        final totalOrders = orders.length;
                        final pendingOrders = orders.where((o) => (o['status'] == 'PENDING')).length;
                        final completedOrders = orders.where((o) => (o['status'] == 'DELIVERED')).length;

                        // Calculate Today & Month Revenue
                        final now = DateTime.now();
                        double revToday = 0.0;
                        double revMonth = 0.0;

                        for (var o in orders) {
                          final amt = (o['totalAmount'] as num? ?? 0.0).toDouble();
                          final dtStr = o['createdAt'];
                          DateTime? dt;
                          if (dtStr is String) dt = DateTime.tryParse(dtStr);

                          if (dt != null) {
                            if (dt.year == now.year && dt.month == now.month) {
                              revMonth += amt;
                              if (dt.day == now.day) {
                                revToday += amt;
                              }
                            }
                          } else {
                            revMonth += amt;
                          }
                        }

                        return StreamBuilder<List<Map<String, dynamic>>>(
                          stream: service.getShopMachineryRequestsStream(),
                          builder: (context, machSnapshot) {
                            final machineryReqs = machSnapshot.data ?? [];
                            final activeRentals = machineryReqs.where((m) => (m['status'] == 'Assigned' || m['status'] == 'Rental Started' || m['status'] == 'Accepted')).length;

                            return StreamBuilder<List<Map<String, dynamic>>>(
                              stream: service.getCropOffersStream(),
                              builder: (context, procSnapshot) {
                                final cropOffers = procSnapshot.data ?? [];
                                final pendingProcurement = cropOffers.where((c) => (c['status'] == 'PENDING' || c['status'] == 'NEGOTIATING')).length;

                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.5,
                                  children: [
                                    _buildMetricCard(Icons.inventory_2_rounded, 'Total Products', '$totalProd', AppTheme.primaryGreen),
                                    _buildMetricCard(Icons.local_shipping_rounded, 'Total Orders', '$totalOrders', Colors.blue),
                                    _buildMetricCard(Icons.pending_actions_rounded, 'Pending Orders', '$pendingOrders', AppTheme.accentGold),
                                    _buildMetricCard(Icons.check_circle_rounded, 'Completed Orders', '$completedOrders', Colors.teal),
                                    _buildMetricCard(Icons.today_rounded, 'Revenue Today', '₹${revToday.toStringAsFixed(0)}', Colors.indigo),
                                    _buildMetricCard(Icons.calendar_month_rounded, 'Revenue This Month', '₹${revMonth.toStringAsFixed(0)}', Colors.deepOrange),
                                    _buildMetricCard(Icons.agriculture_rounded, 'Active Rentals', '$activeRentals', Colors.purple),
                                    _buildMetricCard(Icons.scale_rounded, 'Crop Procurement', '$pendingProcurement', Colors.amber.shade800),
                                    _buildMetricCard(Icons.warning_amber_rounded, 'Low Stock Alerts', '$lowStockCount', Colors.redAccent),
                                    _buildMetricCard(Icons.notifications_active_rounded, 'Notifications', '2 New', Colors.pink),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Quick Actions Grid
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _buildQuickActionTile(Icons.inventory_2_rounded, trans.translate('inventory'), AppTheme.primaryGreen, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
                    }),
                    _buildQuickActionTile(Icons.shopping_cart_rounded, trans.translate('orders'), Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                    }),
                    _buildQuickActionTile(Icons.agriculture_rounded, 'Machinery', Colors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopMachineryScreen()));
                    }),
                    _buildQuickActionTile(Icons.scale_rounded, trans.translate('procurement'), AppTheme.accentGold, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CropPurchasesScreen()));
                    }),
                    _buildQuickActionTile(Icons.people_alt_rounded, 'Customers', Colors.teal, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopCustomersScreen()));
                    }),
                    _buildQuickActionTile(Icons.bar_chart_rounded, 'Analytics', Colors.indigo, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopAnalyticsScreen()));
                    }),
                    _buildQuickActionTile(Icons.notifications_active_rounded, 'Alerts', Colors.pink, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopNotificationsScreen()));
                    }),
                    _buildQuickActionTile(Icons.search_rounded, 'Global Search', Colors.deepOrange, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopSearchScreen()));
                    }),
                    _buildQuickActionTile(Icons.storefront_rounded, trans.translate('profile'), Colors.brown, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopProfileScreen()));
                    }),
                  ],
                ),
                const SizedBox(height: 28),

                // Recent Orders Preview Section
                _buildRecentOrdersSection(service),
                const SizedBox(height: 24),

                // Recent Machinery Rental Requests Preview
                _buildRecentMachinerySection(service),
                const SizedBox(height: 24),

                // Recent Crop Procurement Requests Preview
                _buildRecentProcurementSection(service),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    return WebLayoutShell(
      currentTab: WebTab.dashboard,
      role: 'shop',
      child: content,
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(FirestoreService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Sales Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
              child: const Text('View All'),
            ),
          ],
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.getShopOrdersStream(_shopId),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No recent sales orders', style: TextStyle(color: Colors.grey, fontSize: 13))),
              );
            }

            final recent = orders.take(3).toList();
            return Column(
              children: recent.map((o) {
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_rounded, color: Colors.blue),
                    title: Text(o['farmerName'] as String? ?? 'Farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('ID: ${o['orderId']} • Status: ${o['status']}'),
                    trailing: Text('₹${o['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentMachinerySection(FirestoreService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Rental Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopMachineryScreen())),
              child: const Text('View All'),
            ),
          ],
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.getShopMachineryRequestsStream(),
          builder: (context, snapshot) {
            final reqs = snapshot.data ?? [];
            if (reqs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No machinery requests', style: TextStyle(color: Colors.grey, fontSize: 13))),
              );
            }

            final recent = reqs.take(3).toList();
            return Column(
              children: recent.map((m) {
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.agriculture_rounded, color: Colors.purple),
                    title: Text(m['machineryName'] as String? ?? 'Machinery', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Farmer: ${m['farmerName']} • Status: ${m['status']}'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentProcurementSection(FirestoreService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Crop Offers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropPurchasesScreen())),
              child: const Text('View All'),
            ),
          ],
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.getCropOffersStream(),
          builder: (context, snapshot) {
            final offers = snapshot.data ?? [];
            if (offers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No crop sale offers', style: TextStyle(color: Colors.grey, fontSize: 13))),
              );
            }

            final recent = offers.take(3).toList();
            return Column(
              children: recent.map((c) {
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.scale_rounded, color: AppTheme.accentGold),
                    title: Text('${c['crop']} (${c['weight']} kg)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Farmer: ${c['farmerName']} • Bid: ₹${c['pricePerKg']}/kg'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
