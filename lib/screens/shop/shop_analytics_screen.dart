import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ShopAnalyticsScreen extends StatefulWidget {
  const ShopAnalyticsScreen({super.key});

  @override
  State<ShopAnalyticsScreen> createState() => _ShopAnalyticsScreenState();
}

class _ShopAnalyticsScreenState extends State<ShopAnalyticsScreen> {
  String _shopId = 'SHOP1234';
  bool _isLoading = true;

  // Analytics Metrics
  double _totalSalesRevenue = 45000.0;
  double _totalInventoryValue = 128500.0;
  double _totalProcurementSpend = 46500.0;
  double _totalMachineryEarnings = 14200.0;

  final List<double> _monthlySales = [22000, 28000, 35000, 31000, 42000, 39000, 48000, 52000, 45000, 0, 0, 0];
  final List<double> _dailySales = [4500, 6200, 3800, 8900, 7100, 5400, 9100];
  Map<String, int> _orderStatusCounts = {'DELIVERED': 18, 'DISPATCHED': 5, 'PENDING': 3, 'CANCELLED': 1};
  final List<Map<String, dynamic>> _topProducts = [
    {'name': 'Hybrid Cotton Seeds H-4', 'sales': 42000, 'qty': 120},
    {'name': 'Basmati Rice Seeds', 'sales': 31000, 'qty': 35},
    {'name': 'Organic Neem Cake', 'sales': 18500, 'qty': 44},
    {'name': '16L Knapsack Sprayer', 'sales': 14400, 'qty': 12},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      _shopId = phone;
    }

    try {
      final service = FirestoreService();
      final products = await service.getShopProductsStream(_shopId).first;
      final orders = await service.getShopOrdersStream(_shopId).first;
      final purchases = await service.getShopPurchasesStream(_shopId).first;
      final machinery = await service.getShopMachineryRequestsStream().first;

      if (products.isNotEmpty || orders.isNotEmpty || purchases.isNotEmpty) {
        // Calculate Inventory Value
        double invVal = 0.0;
        for (var p in products) {
          final stock = (p['stock'] as num? ?? 0).toDouble();
          final price = (p['price'] as num? ?? 0.0).toDouble();
          invVal += (stock * price);
        }
        if (invVal > 0) _totalInventoryValue = invVal;

        // Calculate Orders revenue & status counts
        double salesRev = 0.0;
        Map<String, int> statusMap = {};
        for (var o in orders) {
          final status = (o['status'] as String? ?? 'PENDING').toUpperCase();
          statusMap[status] = (statusMap[status] ?? 0) + 1;
          final amt = (o['totalAmount'] as num? ?? 0.0).toDouble();
          if (status == 'DELIVERED' || status == 'DISPATCHED' || status == 'ACCEPTED') {
            salesRev += amt;
          }
        }
        if (salesRev > 0) _totalSalesRevenue = salesRev;
        if (statusMap.isNotEmpty) _orderStatusCounts = statusMap;

        // Calculate Procurement spend
        double procSpend = 0.0;
        for (var pur in purchases) {
          procSpend += (pur['totalAmount'] as num? ?? 0.0).toDouble();
        }
        if (procSpend > 0) _totalProcurementSpend = procSpend;

        // Calculate Machinery earnings
        double machEarn = 0.0;
        for (var m in machinery) {
          final status = m['status'] ?? '';
          if (status == 'Completed' || status == 'Rental Completed' || status == 'Accepted') {
            machEarn += (m['paymentAmount'] as num? ?? 1200.0).toDouble();
          }
        }
        if (machEarn > 0) _totalMachineryEarnings = machEarn;
      }
    } catch (e) {
      debugPrint('[SHOP_ANALYTICS] Error fetching live analytics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Sales & Business Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Summary Cards Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _buildSummaryCard('Sales Revenue', '₹${_totalSalesRevenue.toStringAsFixed(0)}', Icons.payments_rounded, AppTheme.primaryGreen),
                        _buildSummaryCard('Inventory Value', '₹${_totalInventoryValue.toStringAsFixed(0)}', Icons.inventory_2_rounded, Colors.blue),
                        _buildSummaryCard('Procurement Spend', '₹${_totalProcurementSpend.toStringAsFixed(0)}', Icons.scale_rounded, AppTheme.accentGold),
                        _buildSummaryCard('Machinery Earnings', '₹${_totalMachineryEarnings.toStringAsFixed(0)}', Icons.agriculture_rounded, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Monthly Sales Bar Chart
                    _buildChartCard(
                      title: 'Monthly Sales Revenue (2026)',
                      subtitle: 'Total gross sales per calendar month in INR',
                      child: SizedBox(
                        height: 200,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: BarChartPainter(_monthlySales, AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daily Sales Line Trend Chart
                    _buildChartCard(
                      title: 'Daily Sales Trend (Past 7 Days)',
                      subtitle: 'Daily sales volume overview',
                      child: SizedBox(
                        height: 180,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: LineChartPainter(_dailySales, AppTheme.accentGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Status Breakdown & Top Products
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildChartCard(
                            title: 'Order Status Distribution',
                            subtitle: 'Breakdown of total order volume',
                            child: SizedBox(
                              height: 180,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: DonutChartPainter(_orderStatusCounts),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Selling Products List
                    _buildTopProductsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTopProductsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Performing Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Best selling items sorted by gross revenue', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._topProducts.map((p) {
            final double sales = (p['sales'] as num).toDouble();
            final double progress = (sales / 50000).clamp(0.1, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('₹${sales.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade100,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Custom Painters for Charts

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color barColor;
  BarChartPainter(this.values, this.barColor);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.reduce(max) > 0 ? values.reduce(max) : 1.0;
    final double barWidth = (size.width / values.length) * 0.6;
    final double spacing = (size.width / values.length) * 0.4;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    // Draw horizontal gridlines
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final monthLabels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    for (int i = 0; i < values.length; i++) {
      final x = (barWidth + spacing) * i + spacing / 2;
      final barHeight = (values[i] / maxVal) * (size.height - 20);
      final y = size.height - 20 - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      // Label
      TextSpan span = TextSpan(
        text: monthLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
      );
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x + (barWidth - tp.width) / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  LineChartPainter(this.values, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(max) > 0 ? values.reduce(max) : 1.0;
    final stepX = size.width / (values.length - 1);

    final path = Path();
    final fillPath = Path();

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / maxVal) * (size.height - 20) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}

class DonutChartPainter extends CustomPainter {
  final Map<String, int> statusCounts;
  DonutChartPainter(this.statusCounts);

  @override
  void paint(Canvas canvas, Size size) {
    final total = statusCounts.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final colors = {
      'DELIVERED': AppTheme.primaryGreen,
      'DISPATCHED': Colors.blue,
      'PENDING': AppTheme.accentGold,
      'CANCELLED': Colors.redAccent,
    };

    double startAngle = -pi / 2;

    statusCounts.forEach((status, count) {
      final sweepAngle = (count / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[status] ?? Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
