import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class ShopVerificationScreen extends StatefulWidget {
  const ShopVerificationScreen({super.key});

  @override
  State<ShopVerificationScreen> createState() => _ShopVerificationScreenState();
}

class _ShopVerificationScreenState extends State<ShopVerificationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    try {
      final allUsers = await FirestoreService().getAllUsers();
      _shops = allUsers.where((u) => (u['role'] ?? '') == 'shop').toList();

      // Seed fallback shops if empty
      if (_shops.isEmpty) {
        _shops = [
          {
            'uid': 'SHOP101',
            'shopName': 'Sri Rama Seeds & Fertilizers',
            'owner': 'Sreenivas Rao',
            'license': 'AP-GNT-2026-8812',
            'gst': '37AAAAA0000A1Z5',
            'phone': '9876543210',
            'address': 'Main Road, Guntur',
            'district': 'Guntur',
            'verificationStatus': 'PENDING',
          },
          {
            'uid': 'SHOP102',
            'shopName': 'Balaji Agro Chemicals',
            'owner': 'Balaji Naidu',
            'license': 'AP-KRN-2026-9941',
            'gst': '37BBBBB1111B2Z6',
            'phone': '9000122233',
            'address': 'Kothapet, Vijayawada',
            'district': 'Krishna',
            'verificationStatus': 'Approved',
          },
        ];
      }
    } catch (e) {
      debugPrint('[SHOP_VERIFY] Error loading shops: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String uid, String status) async {
    try {
      await FirestoreService().updateShopVerificationStatus(uid, status);
      await FirestoreService().logAuditEvent(
        userId: 'ADMIN',
        action: 'Updated Shop Verification',
        category: 'ADMIN',
        details: 'Shop $uid status set to $status',
      );
      _loadShops();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shop verification status updated to $status!'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Merchant License Approvals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShops,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shop Verification Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const SizedBox(height: 4),
              Text('Audit retail input dealer licenses, GST numbers, and physical premises.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : _shops.isEmpty
                        ? const Center(child: Text('No distributor applications found.'))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _shops.length,
                            itemBuilder: (context, index) {
                              final shop = _shops[index];
                              final status = shop['verificationStatus'] ?? shop['status'] ?? 'PENDING';
                              final isApproved = status == 'Approved';
                              final isRejected = status == 'Rejected';

                              final color = isApproved
                                  ? AppTheme.primaryGreen
                                  : (isRejected ? Colors.redAccent : AppTheme.accentGold);

                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.storefront_rounded, color: AppTheme.primaryGreen, size: 24),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              shop['shopName'] as String? ?? 'Agri Shop',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      Text('👤 Owner: ${shop['owner'] ?? 'N/A'} • 📞 Phone: ${shop['phone']}'),
                                      const SizedBox(height: 4),
                                      Text('📜 License: ${shop['license'] ?? 'N/A'} • GST: ${shop['gst'] ?? 'N/A'}'),
                                      const SizedBox(height: 4),
                                      Text('📍 Address: ${shop['address'] ?? 'Address'}, ${shop['district'] ?? 'District'}'),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _updateStatus(shop['uid'], 'Rejected'),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                              child: const Text('REJECT'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _updateStatus(shop['uid'], 'Suspended'),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                                              child: const Text('SUSPEND'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _updateStatus(shop['uid'], 'Approved'),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                                              child: const Text('APPROVE', style: TextStyle(color: Colors.white)),
                                            ),
                                          ),
                                        ],
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
        ),
      ),
    );
  }
}
