import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class CropPurchasesScreen extends StatefulWidget {
  const CropPurchasesScreen({super.key});

  @override
  State<CropPurchasesScreen> createState() => _CropPurchasesScreenState();
}

class _CropPurchasesScreenState extends State<CropPurchasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _shopId = 'SHOP1234';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showNegotiateDialog(Map<String, dynamic> offer) {
    final offerId = offer['offerId'] as String;
    final currentPrice = (offer['pricePerKg'] as num? ?? 0.0).toDouble();
    final counterCtrl = TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Negotiate Counter Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farmer Requested Bid: ₹$currentPrice/kg', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: counterCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Counter Price (₹/kg)',
                hintText: 'Enter your counter offer per kg',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final counterVal = double.tryParse(counterCtrl.text);
              if (counterVal != null && counterVal > 0) {
                Navigator.pop(ctx);
                await FirestoreService().negotiateCropOffer(offerId, counterVal, _shopId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Counter offer sent: ₹$counterVal/kg'),
                      backgroundColor: AppTheme.accentGold,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
            child: const Text('SEND COUNTER OFFER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processOffer(Map<String, dynamic> offer, String action) async {
    final offerId = offer['offerId'] as String;

    try {
      if (action == 'ACCEPT') {
        final double weight = (offer['weight'] as num? ?? 0.0).toDouble();
        final double price = (offer['pricePerKg'] as num? ?? 0.0).toDouble();
        final double total = weight * price;

        final purchaseData = {
          'farmerId': offer['farmerId'] ?? 'FAR1234',
          'farmerName': offer['farmerName'] ?? 'Farmer',
          'crop': offer['crop'] ?? 'Crop',
          'weight': weight,
          'pricePerKg': price,
          'totalAmount': total,
          'village': offer['village'] ?? 'Local Village',
          'qualityGrade': offer['qualityGrade'] ?? 'Grade A',
          'moisture': offer['moisture'] ?? '12%',
        };

        await FirestoreService().acceptCropOffer(offerId, _shopId, purchaseData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crop offer ACCEPTED! Added to Purchase History.'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else if (action == 'REJECT') {
        await FirestoreService().updateCropOfferStatus(offerId, 'REJECTED');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crop offer rejected.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(trans.translate('procurement'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Crop Sale Offers'),
            Tab(text: 'Procurement History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffersTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOffersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getCropOffersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        var requests = snapshot.data ?? [];

        // Pre-seed demo offers if empty
        if (requests.isEmpty) {
          requests = [
            {
              'offerId': 'off_101',
              'crop': 'Cotton (H4)',
              'farmerName': 'Rajesh Kumar',
              'farmerId': '9876543210',
              'village': 'Ramapuram',
              'weight': 1500.0,
              'pricePerKg': 64.0,
              'moisture': '11%',
              'qualityGrade': 'Premium Grade A',
              'status': 'PENDING',
            },
            {
              'offerId': 'off_102',
              'crop': 'Sona Masoori Paddy',
              'farmerName': 'Venkateswarlu Naidu',
              'farmerId': '9848022334',
              'village': 'Tadikonda',
              'weight': 2800.0,
              'pricePerKg': 24.5,
              'moisture': '13.5%',
              'qualityGrade': 'Grade A',
              'status': 'NEGOTIATING',
              'counterPricePerKg': 23.0,
            },
          ];
        }

        final pendingOffers = requests.where((r) => r['status'] != 'ACCEPTED' && r['status'] != 'REJECTED').toList();

        if (pendingOffers.isEmpty) {
          return const Center(child: Text('No active crop offers submitted.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: pendingOffers.length,
          itemBuilder: (context, index) {
            final req = pendingOffers[index];
            final String status = req['status'] as String? ?? 'PENDING';
            final double weight = (req['weight'] as num? ?? 0.0).toDouble();
            final double pricePerKg = (req['pricePerKg'] as num? ?? 0.0).toDouble();

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
                        const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 22),
                        const SizedBox(width: 8),
                        Text(req['crop'] as String? ?? 'Crop Offer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'NEGOTIATING' ? AppTheme.accentGold.withValues(alpha: 0.15) : AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'NEGOTIATING' ? AppTheme.accentGold : AppTheme.primaryGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Farmer: ${req['farmerName']} • 📍 ${req['village'] ?? 'Local Village'}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPropChip('Weight', '$weight kg'),
                        const SizedBox(width: 8),
                        _buildPropChip('Moisture', req['moisture'] ?? '12%'),
                        const SizedBox(width: 8),
                        _buildPropChip('Quality', req['qualityGrade'] ?? 'Grade A'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Farmer Price Bid', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            Text('₹$pricePerKg / kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                          ],
                        ),
                        if (req['counterPricePerKg'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Counter Offer Sent', style: TextStyle(fontSize: 11, color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
                              Text('₹${req['counterPricePerKg']} / kg', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _processOffer(req, 'ACCEPT'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                            child: const Text('ACCEPT OFFER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showNegotiateDialog(req),
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentGold),
                            child: const Text('NEGOTIATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () => _processOffer(req, 'REJECT'),
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
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getShopPurchasesStream(_shopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final purchases = snapshot.data ?? [];
        if (purchases.isEmpty) {
          return const Center(child: Text('No completed crop purchases in history.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final p = purchases[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen),
                title: Text('${p['crop']} (${p['weight']} kg)', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Farmer: ${p['farmerName']} • Rate: ₹${p['pricePerKg']}/kg'),
                trailing: Text('₹${p['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPropChip(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $val', style: const TextStyle(fontSize: 11, color: Colors.black87)),
    );
  }
}
