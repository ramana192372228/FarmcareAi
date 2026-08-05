import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _shopId = 'SHOP1234';
  String _statusFilter = 'ALL';

  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'ACCEPTED',
    'PACKED',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _initializeShop();
  }

  Future<void> _initializeShop() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      setState(() {
        _shopId = phone;
      });
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await FirestoreService().updateOrderStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $status'),
            backgroundColor: status == 'DELIVERED' ? AppTheme.primaryGreen : AppTheme.accentGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generateInvoicePdf(Map<String, dynamic> order) async {
    final doc = pw.Document();

    final orderId = order['orderId'] as String? ?? 'ORD-000';
    final farmerName = order['farmerName'] as String? ?? 'Farmer';
    final farmerPhone = order['farmerPhone'] as String? ?? 'N/A';
    final address = order['address'] as String? ?? 'N/A';
    final items = order['items'] as List? ?? [];
    final totalAmount = (order['totalAmount'] as num? ?? 0.0).toDouble();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FarmCare AI Agri Business', style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        pw.Text('Tax Invoice / Cash Receipt', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text('INVOICE', style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.green800),
                pw.SizedBox(height: 12),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Billed To:', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Customer: $farmerName'),
                        pw.Text('Phone: $farmerPhone'),
                        pw.Text('Address: $address'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice Details:', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Invoice ID: #$orderId'),
                        pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                        pw.Text('Payment: ${order['paymentStatus'] ?? 'COD'}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.TableHelper.fromTextArray(
                  headers: ['Item Name', 'Qty', 'Unit Price', 'Total'],
                  data: items.map((item) {
                    final pName = item['productName'] ?? 'Product';
                    final qty = item['quantity'] ?? 1;
                    final price = (item['price'] as num? ?? 0.0).toDouble();
                    return [pName, '$qty', '₹${price.toStringAsFixed(2)}', '₹${(qty * price).toStringAsFixed(2)}'];
                  }).toList(),
                  headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                  cellHeight: 28,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Grand Total: ', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹${totalAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Thank you for choosing FarmCare AI Quality Seeds & Agri Inputs!', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(trans.translate('orders'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _statuses.map((st) {
                    final isSel = _statusFilter == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(st),
                        selected: isSel,
                        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSel ? AppTheme.primaryGreen : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setState(() => _statusFilter = st),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getShopOrdersStream(_shopId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No sales orders found.', style: TextStyle(color: Colors.grey)));
                    }

                    var orders = snapshot.data!;

                    // Filter
                    if (_statusFilter != 'ALL') {
                      orders = orders.where((o) => (o['status'] ?? 'PENDING') == _statusFilter).toList();
                    }

                    if (orders.isEmpty) {
                      return Center(child: Text('No orders matching status "$_statusFilter"', style: const TextStyle(color: Colors.grey)));
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final String orderId = order['orderId'] as String? ?? '';
                        final String status = order['status'] as String? ?? 'PENDING';
                        final String farmerName = order['farmerName'] as String? ?? 'Farmer';
                        final String farmerPhone = order['farmerPhone'] as String? ?? 'N/A';
                        final String address = order['address'] as String? ?? 'Local Village';
                        final List items = order['items'] as List? ?? [];
                        final double totalAmount = (order['totalAmount'] as num? ?? 0.0).toDouble();

                        Color statusColor = Colors.orange;
                        if (status == 'ACCEPTED') statusColor = Colors.blue;
                        if (status == 'PACKED') statusColor = Colors.purple;
                        if (status == 'OUT_FOR_DELIVERY') statusColor = Colors.indigo;
                        if (status == 'DELIVERED') statusColor = AppTheme.primaryGreen;
                        if (status == 'CANCELLED') statusColor = Colors.redAccent;

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bookmark_border_rounded, color: AppTheme.primaryGreen, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Order #${orderId.toUpperCase()}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Farmer: $farmerName (📞 $farmerPhone)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('📍 Delivery Address: $address', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                const SizedBox(height: 10),
                                const Text('Ordered Products:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 4),
                                ...items.map((it) {
                                  return Text('• ${it['productName']} x ${it['quantity']} @ ₹${it['price']}', style: const TextStyle(fontSize: 13));
                                }),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Amount', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                        Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                      ],
                                    ),
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      onPressed: () => _generateInvoicePdf(order),
                                      icon: const Icon(Icons.print_rounded, size: 16),
                                      label: const Text('INVOICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Workflow Actions Bar
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (status == 'PENDING') ...[
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(orderId, 'ACCEPTED'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                        child: const Text('ACCEPT ORDER', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _updateStatus(orderId, 'CANCELLED'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                        child: const Text('REJECT', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                    if (status == 'ACCEPTED')
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(orderId, 'PACKED'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                        child: const Text('MARK PACKED', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    if (status == 'PACKED')
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(orderId, 'OUT_FOR_DELIVERY'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                        child: const Text('OUT FOR DELIVERY', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    if (status == 'OUT_FOR_DELIVERY')
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(orderId, 'DELIVERED'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                                        child: const Text('MARK DELIVERED', style: TextStyle(color: Colors.white, fontSize: 11)),
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
    );
  }
}
