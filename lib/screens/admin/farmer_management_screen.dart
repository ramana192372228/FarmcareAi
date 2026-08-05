import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class FarmerManagementScreen extends StatefulWidget {
  const FarmerManagementScreen({super.key});

  @override
  State<FarmerManagementScreen> createState() => _FarmerManagementScreenState();
}

class _FarmerManagementScreenState extends State<FarmerManagementScreen> {
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _farmers = [];

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    setState(() => _isLoading = true);
    try {
      final service = FirestoreService();
      final allUsers = await service.getAllUsers();
      _farmers = allUsers.where((u) => (u['role'] ?? 'farmer') == 'farmer').toList();

      // Seed demo farmers if empty
      if (_farmers.isEmpty) {
        _farmers = [
          {
            'uid': 'FAR1234',
            'name': 'Rajesh Kumar',
            'phone': '9876543210',
            'email': 'rajesh.kumar@gmail.com',
            'village': 'Ramapuram',
            'district': 'Guntur',
            'landSize': '4.5 Acres',
            'cropCount': 2,
            'ordersCount': 6,
            'reportsCount': 3,
            'status': 'Active',
          },
          {
            'uid': 'FAR5678',
            'name': 'Venkateswarlu Naidu',
            'phone': '9848022334',
            'email': 'vnaidu@yahoo.com',
            'village': 'Tadikonda',
            'district': 'Guntur',
            'landSize': '8.0 Acres',
            'cropCount': 4,
            'ordersCount': 11,
            'reportsCount': 5,
            'status': 'Active',
          },
          {
            'uid': 'FAR9900',
            'name': 'Kondal Rao',
            'phone': '9912345678',
            'email': 'kondal.r@gmail.com',
            'village': 'Mangalagiri',
            'district': 'Guntur',
            'landSize': '3.0 Acres',
            'cropCount': 1,
            'ordersCount': 2,
            'reportsCount': 1,
            'status': 'Suspended',
          },
        ];
      }
    } catch (e) {
      debugPrint('[FARMER_MGMT] Error loading farmers: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String uid, String status) async {
    try {
      await FirestoreService().updateUserStatus(uid, status);
      await FirestoreService().logAuditEvent(
        userId: 'ADMIN',
        action: 'Updated Farmer Status',
        category: 'ADMIN',
        details: 'Farmer $uid status changed to $status',
      );
      _loadFarmers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Farmer $uid status updated to $status'), backgroundColor: AppTheme.primaryGreen),
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

  Future<void> _deleteFarmer(String uid, String name) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Farmer Account?'),
        content: Text('Are you sure you want to permanently delete $name ($uid)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteUserDoc(uid);
              await FirestoreService().logAuditEvent(
                userId: 'ADMIN',
                action: 'Deleted Farmer Account',
                category: 'ADMIN',
                details: 'Deleted farmer $name ($uid)',
              );
              _loadFarmers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _farmers.where((f) {
      final name = (f['name'] ?? '').toString().toLowerCase();
      final phone = (f['phone'] ?? '').toString().toLowerCase();
      final village = (f['village'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || phone.contains(q) || village.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Farmer Management Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search farmer name, phone, village...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : filtered.isEmpty
                        ? const Center(child: Text('No registered farmers found.'))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final f = filtered[index];
                              final status = f['status'] ?? 'Active';
                              final isSuspended = status == 'Suspended';

                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isSuspended ? Colors.redAccent.withValues(alpha: 0.15) : AppTheme.primaryGreen.withValues(alpha: 0.15),
                                            child: Icon(Icons.agriculture_rounded, color: isSuspended ? Colors.redAccent : AppTheme.primaryGreen),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(f['name'] as String? ?? 'Farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                Text('📞 ${f['phone']} • 📍 ${f['village'] ?? 'Village'}, ${f['district'] ?? 'District'}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isSuspended ? Colors.redAccent.withValues(alpha: 0.12) : AppTheme.primaryGreen.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSuspended ? Colors.redAccent : AppTheme.primaryGreen)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildBadge('Land Size', f['landSize'] ?? '5.0 Acres'),
                                          _buildBadge('Crops', '${f['cropCount'] ?? 2} Active'),
                                          _buildBadge('Orders', '${f['ordersCount'] ?? 4} Placed'),
                                          _buildBadge('Soil Reports', '${f['reportsCount'] ?? 2} Logged'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (!isSuspended)
                                            OutlinedButton.icon(
                                              onPressed: () => _updateStatus(f['uid'], 'Suspended'),
                                              icon: const Icon(Icons.block_rounded, size: 16),
                                              label: const Text('SUSPEND', style: TextStyle(fontSize: 11)),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                                            ),
                                          if (isSuspended)
                                            ElevatedButton.icon(
                                              onPressed: () => _updateStatus(f['uid'], 'Active'),
                                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                                              label: const Text('ACTIVATE', style: TextStyle(fontSize: 11, color: Colors.white)),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                                            ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                            onPressed: () => _deleteFarmer(f['uid'], f['name'] ?? 'Farmer'),
                                            tooltip: 'Delete Farmer',
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

  Widget _buildBadge(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
