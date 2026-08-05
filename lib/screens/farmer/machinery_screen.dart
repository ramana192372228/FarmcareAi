import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class MachineryScreen extends StatefulWidget {
  const MachineryScreen({super.key});

  @override
  State<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends State<MachineryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedMachinery;
  String? _selectedRate;
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  String _farmerId = '';

  static const List<Map<String, dynamic>> _machinery = [
    {'name': 'Tractor (45 HP)', 'rate': '₹800/hour', 'icon': Icons.agriculture_rounded, 'color': Color(0xFF2E7D32), 'desc': 'Ploughing, puddling, land levelling. Includes operator.'},
    {'name': 'Rotavator', 'rate': '₹600/hour', 'icon': Icons.settings_rounded, 'color': Colors.blueAccent, 'desc': 'Soil tillage, straw incorporation, seedbed preparation.'},
    {'name': 'Knapsack Sprayer', 'rate': '₹200/hour', 'icon': Icons.water_drop_rounded, 'color': Colors.cyan, 'desc': 'Manual spraying for pesticides, herbicides, fungicides.'},
    {'name': 'Power Weeder', 'rate': '₹350/hour', 'icon': Icons.grass_rounded, 'color': Colors.orange, 'desc': 'Mechanical inter-crop weeding. Reduce labour cost significantly.'},
    {'name': 'Paddy Transplanter', 'rate': '₹1200/hour', 'icon': Icons.grid_3x3_rounded, 'color': Colors.teal, 'desc': 'Mechanized paddy transplanting. Saves 60% transplanting labour.'},
    {'name': 'Mini Harvester', 'rate': '₹2,500/day', 'icon': Icons.handshake_rounded, 'color': Color(0xFFF9A826), 'desc': 'Crop harvesting for paddy, wheat, soybean. Reduces post-harvest losses.'},
    {'name': 'Drone Sprayer', 'rate': '₹1,500/acre', 'icon': Icons.flight_rounded, 'color': Colors.purple, 'desc': 'UAV-based precision pesticide/fertilizer spray. Covers 1 acre in 10 min.'},
    {'name': 'Soil Testing Kit (Mobile)', 'rate': '₹100/sample', 'icon': Icons.science_rounded, 'color': Colors.brown, 'desc': 'On-site NPK, pH, EC soil analysis. Report in 30 minutes.'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFarmerId();
  }

  Future<void> _loadFarmerId() async {
    final phone = await AuthService().getLoggedUserPhone();
    setState(() {
      _farmerId = phone ?? 'anonymous_farmer';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _book() async {
    if (_selectedMachinery == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a machinery type.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a booking date.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profile = await AuthService().getUserProfile(_farmerId);
      final farmerName = profile?.name ?? 'Farmer ($_farmerId)';

      final Map<String, dynamic> requestData = {
        'farmerId': _farmerId,
        'farmerName': farmerName,
        'machineryName': _selectedMachinery,
        'rate': _selectedRate ?? '',
        'bookingDate': _fmt(_selectedDate!),
        'status': 'Pending',
      };

      await FirestoreService().saveMachineryRequest(requestData);

      setState(() {
        _isSubmitting = false;
        _selectedMachinery = null;
        _selectedDate = null;
      });

      _tabController.animateTo(1); // Switch to My Requests tab

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Machinery rental request submitted! Tracking status in My Requests.'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Farm Machinery', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Request Rental'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestTab(),
            _buildMyRequestsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.agriculture_rounded, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Farm Machinery Booking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 3),
                      Text('Rent tractors, sprayers, harvesters & more at subsidized rates from your cooperative.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('AVAILABLE MACHINERY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.3)),
          const SizedBox(height: 14),

          ..._machinery.map((m) => _machineryTile(m)),
          const SizedBox(height: 20),

          // Booking form
          if (_selectedMachinery != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.agriculture_rounded, color: AppTheme.primaryGreen),
                        const SizedBox(width: 10),
                        Text('$_selectedMachinery ($_selectedRate)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_rounded, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          Text(_selectedDate != null ? _fmt(_selectedDate!) : 'Select booking date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _selectedDate == null ? Colors.grey : Colors.black87)),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _book,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.event_available_rounded, color: Colors.white),
                      label: Text(_isSubmitting ? 'SUBMITTING...' : 'SUBMIT RENTAL REQUEST', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getFarmerMachineryRequestsStream(_farmerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 72, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No Rental Requests Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Select machinery on "Request Rental" tab to submit a request.', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final status = req['status'] ?? 'Pending';
            final machineryName = req['machineryName'] ?? 'Machinery';
            final bookingDate = req['bookingDate'] ?? 'N/A';
            final rate = req['rate'] ?? '';

            Color statusColor = Colors.amber;
            IconData statusIcon = Icons.pending_rounded;
            if (status == 'Accepted') {
              statusColor = AppTheme.primaryGreen;
              statusIcon = Icons.check_circle_rounded;
            } else if (status == 'Rejected') {
              statusColor = Colors.redAccent;
              statusIcon = Icons.cancel_rounded;
            } else if (status == 'Completed') {
              statusColor = Colors.blue;
              statusIcon = Icons.verified_rounded;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(statusIcon, color: statusColor),
                ),
                title: Text(machineryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Booking Date: $bookingDate\nRate: $rate', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _machineryTile(Map<String, dynamic> m) {
    final color = m['color'] as Color;
    final isSelected = _selectedMachinery == m['name'];
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMachinery = m['name'] as String;
        _selectedRate = m['rate'] as String;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.12), width: isSelected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(m['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 3),
                  Text(m['desc'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(m['rate'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
