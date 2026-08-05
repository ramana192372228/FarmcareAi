import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class MyFarmScreen extends StatefulWidget {
  const MyFarmScreen({super.key});

  @override
  State<MyFarmScreen> createState() => _MyFarmScreenState();
}

class _MyFarmScreenState extends State<MyFarmScreen> {
  String _userId = '';
  bool _isLoadingUser = true;

  static const List<String> _crops = ['Cotton', 'Rice', 'Wheat', 'Tomato', 'Beetroot', 'Maize', 'Groundnut', 'Soybean', 'Sugarcane', 'Chilli'];
  static const List<String> _healthStatuses = ['Healthy', 'Requires Attention', 'Harvest Ready', 'Sowing Stage'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final phone = await AuthService().getLoggedUserPhone();
    setState(() {
      _userId = phone ?? 'anonymous';
      _isLoadingUser = false;
    });
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    DateTime? dt;
    if (dateVal is String) dt = DateTime.tryParse(dateVal);
    if (dateVal is int) dt = DateTime.fromMillisecondsSinceEpoch(dateVal);
    if (dt == null) return 'N/A';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _showAddEditCropDialog([Map<String, dynamic>? crop]) {
    final nameCtrl = TextEditingController(text: crop?['cropName'] ?? _crops[0]);
    final varietyCtrl = TextEditingController(text: crop?['variety'] ?? '');
    final acresCtrl = TextEditingController(text: (crop?['acreage'] ?? '1.0').toString());
    DateTime sowingDate = DateTime.tryParse(crop?['sowingDate'] ?? '') ?? DateTime.now();
    String healthStatus = crop?['healthStatus'] ?? 'Healthy';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(crop == null ? 'Add Crop to Farm' : 'Edit Crop Details', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _crops.contains(nameCtrl.text) ? nameCtrl.text : _crops[0],
                  decoration: InputDecoration(
                    labelText: 'Select Crop',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => nameCtrl.text = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: varietyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Crop Variety (Optional)',
                    hintText: 'e.g. Bt Cotton II, Sona Masoori',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: acresCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cultivated Area (Acres)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: sowingDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setModalState(() => sowingDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sowing Date: ${_formatDate(sowingDate.toIso8601String())}'),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: healthStatus,
                  decoration: InputDecoration(
                    labelText: 'Crop Health Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _healthStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => healthStatus = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final acres = double.tryParse(acresCtrl.text.trim()) ?? 1.0;
                final messenger = ScaffoldMessenger.of(context);
                final cropData = {
                  'cropName': nameCtrl.text.trim(),
                  'variety': varietyCtrl.text.trim(),
                  'acreage': acres,
                  'sowingDate': sowingDate.toIso8601String(),
                  'healthStatus': healthStatus,
                };
                Navigator.of(ctx).pop();
                if (crop == null) {
                  await FirestoreService().saveFarmCrop(_userId, cropData);
                } else {
                  final cropId = crop['cropId'] ?? '';
                  await FirestoreService().updateFarmCrop(_userId, cropId, cropData);
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(crop == null ? 'Crop added to farm!' : 'Crop updated successfully!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('SAVE CROP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCrop(String cropId, String cropName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Crop?'),
        content: Text('Are you sure you want to remove $cropName from your farm records?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirestoreService().deleteFarmCrop(_userId, cropId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Crop removed from farm.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('REMOVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Farm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getFarmCropsStream(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                }

                final cropsList = snapshot.data ?? [];
                double totalArea = 0.0;
                for (final c in cropsList) {
                  totalArea += (c['acreage'] as num?)?.toDouble() ?? 0.0;
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farm Overview Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FARM OVERVIEW',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem('Total Land Area', '${totalArea.toStringAsFixed(1)} Acres', Icons.landscape_rounded),
                                Container(width: 1, height: 40, color: Colors.white24),
                                _buildSummaryItem('Active Crops', '${cropsList.length} Crops', Icons.grass_rounded),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddEditCropDialog(),
                                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGreen),
                                label: const Text('ADD NEW CROP TO FARM', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'MY CULTIVATED CROPS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.3),
                      ),
                      const SizedBox(height: 12),

                      if (cropsList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Column(
                              children: [
                                Icon(Icons.agriculture_rounded, size: 72, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No Crops Registered Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Add your first crop to calculate farm statistics and schedules.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        )
                      else
                        ...cropsList.map((c) => _buildCropCard(c)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildCropCard(Map<String, dynamic> c) {
    final cropId = c['cropId'] ?? '';
    final cropName = c['cropName'] ?? 'Crop';
    final variety = c['variety'] as String?;
    final acres = (c['acreage'] as num?)?.toDouble() ?? 1.0;
    final sowingDate = _formatDate(c['sowingDate']);
    final status = c['healthStatus'] ?? 'Healthy';

    Color statusColor = Colors.green;
    if (status == 'Requires Attention') statusColor = Colors.orange;
    if (status == 'Harvest Ready') statusColor = AppTheme.accentGold;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.grass_rounded, color: AppTheme.primaryGreen),
        ),
        title: Text(
          cropName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text('${acres.toStringAsFixed(1)} Acres', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryGreen)),
              if (variety != null && variety.isNotEmpty) Text(' • $variety', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.blue),
              onPressed: () => _showAddEditCropDialog(c),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
              onPressed: () => _confirmDeleteCrop(cropId, cropName),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sowing Date: $sowingDate', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    Text('Status: $status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
