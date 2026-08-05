import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ShopMachineryScreen extends StatefulWidget {
  const ShopMachineryScreen({super.key});

  @override
  State<ShopMachineryScreen> createState() => _ShopMachineryScreenState();
}

class _ShopMachineryScreenState extends State<ShopMachineryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _shopId = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadShopId();
  }

  Future<void> _loadShopId() async {
    final phone = await AuthService().getLoggedUserPhone();
    setState(() {
      _shopId = phone ?? 'shop_admin';
      _isLoadingUser = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditMachineryDialog([Map<String, dynamic>? item]) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final rateCtrl = TextEditingController(text: item?['rate'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final isAvailable = ValueNotifier<bool>(item?['isAvailable'] ?? true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(item == null ? 'Add Machinery Item' : 'Edit Machinery Item', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Machinery Name',
                  hintText: 'e.g. John Deere Tractor (50 HP)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateCtrl,
                decoration: InputDecoration(
                  labelText: 'Rental Rate',
                  hintText: 'e.g. ₹800/hour or ₹3,000/day',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Conditions',
                  hintText: 'Includes driver, fuel extra...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: isAvailable,
                builder: (context, val, _) => SwitchListTile(
                  title: const Text('Available for Rent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  value: val,
                  activeThumbColor: AppTheme.accentGold,
                  onChanged: (newVal) => isAvailable.value = newVal,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || rateCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              final itemId = item?['itemId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
              final itemData = {
                'shopId': _shopId,
                'name': nameCtrl.text.trim(),
                'rate': rateCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'isAvailable': isAvailable.value,
              };
              await FirestoreService().saveMachineryItem(itemId, itemData);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(item == null ? 'Machinery added to inventory!' : 'Machinery updated!'),
                    backgroundColor: AppTheme.accentGold,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAssignMachineAndDriverDialog(Map<String, dynamic> request) {
    final reqId = request['requestId'] as String;
    final driverNameCtrl = TextEditingController(text: request['driverName'] ?? 'Ramesh (Driver)');
    final driverPhoneCtrl = TextEditingController(text: request['driverPhone'] ?? '9876543210');
    final machineNameCtrl = TextEditingController(text: request['assignedMachineName'] ?? request['machineryName'] ?? 'Mahindra Tractor 575');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Machine & Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: machineNameCtrl, decoration: const InputDecoration(labelText: 'Machine Assigned')),
            const SizedBox(height: 10),
            TextField(controller: driverNameCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            const SizedBox(height: 10),
            TextField(controller: driverPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().assignMachineryRental(
                reqId,
                machineId: 'm1',
                machineName: machineNameCtrl.text.trim(),
                driverName: driverNameCtrl.text.trim(),
                driverPhone: driverPhoneCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Machine & driver assigned! Status updated to Assigned.'), backgroundColor: AppTheme.primaryGreen),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('ASSIGN & APPROVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Machinery Rental Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentGold,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Active Rentals'),
            Tab(text: 'Rental Catalog'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRentalRequestsTab(isHistory: false),
                _buildInventoryTab(),
                _buildRentalRequestsTab(isHistory: true),
              ],
            ),
    );
  }

  Widget _buildRentalRequestsTab({required bool isHistory}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getShopMachineryRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
        }

        var requests = snapshot.data ?? [];

        // Filter active vs history
        if (isHistory) {
          requests = requests.where((r) => r['status'] == 'Rental Completed' || r['status'] == 'Payment Completed' || r['status'] == 'Cancelled' || r['status'] == 'Rejected').toList();
        } else {
          requests = requests.where((r) => r['status'] != 'Rental Completed' && r['status'] != 'Payment Completed' && r['status'] != 'Cancelled' && r['status'] != 'Rejected').toList();
        }

        if (requests.isEmpty) {
          return Center(
            child: Text(isHistory ? 'No rental history recorded.' : 'No active rental requests.', style: const TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final reqId = req['requestId'] ?? '';
            final status = req['status'] ?? 'Pending';
            final farmerName = req['farmerName'] ?? req['farmerId'] ?? 'Farmer';
            final machineryName = req['machineryName'] ?? 'Machinery';
            final bookingDate = req['bookingDate'] ?? 'Today';
            final driverName = req['driverName'];
            final driverPhone = req['driverPhone'];

            Color statusColor = Colors.orange;
            if (status == 'Assigned') statusColor = Colors.blue;
            if (status == 'Rental Started') statusColor = Colors.purple;
            if (status == 'Rental Completed' || status == 'Payment Completed') statusColor = AppTheme.primaryGreen;
            if (status == 'Rejected' || status == 'Cancelled') statusColor = Colors.redAccent;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(machineryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Farmer: $farmerName • Booking Date: $bookingDate', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    if (driverName != null) ...[
                      const SizedBox(height: 4),
                      Text('👨‍✈️ Driver: $driverName (📞 $driverPhone)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                    const SizedBox(height: 12),

                    // Stage Workflow Action Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (status == 'Pending' || status == 'Booking Request') ...[
                          ElevatedButton(
                            onPressed: () => _showAssignMachineAndDriverDialog(req),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                            child: const Text('ACCEPT & ASSIGN DRIVER', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          OutlinedButton(
                            onPressed: () => FirestoreService().updateMachineryRequestWorkflow(reqId, 'Cancelled'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                            child: const Text('REJECT', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                        if (status == 'Assigned')
                          ElevatedButton(
                            onPressed: () => FirestoreService().updateMachineryRequestWorkflow(reqId, 'Rental Started'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                            child: const Text('START RENTAL', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        if (status == 'Rental Started')
                          ElevatedButton(
                            onPressed: () => FirestoreService().updateMachineryRequestWorkflow(reqId, 'Rental Completed', paymentAmount: 2400),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                            child: const Text('COMPLETE RENTAL & COLLECT PAYMENT', style: TextStyle(color: Colors.white, fontSize: 11)),
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

  Widget _buildInventoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getMachineryInventoryStream(_shopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditMachineryDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('ADD FIRST MACHINERY', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(item['name'] ?? 'Machinery', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Rate: ${item['rate']} • Status: ${item['isAvailable'] == true ? "Available" : "Busy"}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.accentGold),
                  onPressed: () => _showAddEditMachineryDialog(item),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
