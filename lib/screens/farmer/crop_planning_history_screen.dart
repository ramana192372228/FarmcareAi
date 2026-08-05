import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'crop_planning_screen.dart';

class CropPlanningHistoryScreen extends StatefulWidget {
  const CropPlanningHistoryScreen({super.key});

  @override
  State<CropPlanningHistoryScreen> createState() => _CropPlanningHistoryScreenState();
}

class _CropPlanningHistoryScreenState extends State<CropPlanningHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentUserId = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await AuthService().getLoggedUserPhone();
    setState(() {
      _currentUserId = userId ?? 'anonymous';
      _isLoadingUser = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    DateTime? dt;
    if (dateVal is String) {
      dt = DateTime.tryParse(dateVal);
    }
    if (dt == null) return 'N/A';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _confirmDelete(String planId, String cropName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Crop Plan?'),
        content: Text('Are you sure you want to delete the plan for $cropName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                await FirestoreService().deleteCropPlan(planId);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Crop Plan deleted successfully.'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error deleting plan: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlanDetailsModal(Map<String, dynamic> plan) {
    final cropName = plan['cropName'] ?? 'Unknown Crop';
    final acreage = (plan['acreage'] as num?)?.toDouble() ?? 1.0;
    final plantingDate = _formatDate(plan['plantingDate']);
    final genPlan = plan['generatedPlan'] as Map<String, dynamic>? ?? {};
    final harvestEstimate = genPlan['harvestEstimateText'] ?? '';

    final fertList = (genPlan['fertilizerSchedule'] as List?)
        ?.map((e) => PlanItem.fromJson(Map<String, dynamic>.from(e)))
        .toList() ?? [];
    final pestList = (genPlan['pesticideSchedule'] as List?)
        ?.map((e) => PlanItem.fromJson(Map<String, dynamic>.from(e)))
        .toList() ?? [];
    final inspList = (genPlan['inspectionReminders'] as List?)
        ?.map((e) => PlanItem.fromJson(Map<String, dynamic>.from(e)))
        .toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cropName Advisory Plan',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    Text(
                      'Area: $acreage Acres | Sown: $plantingDate',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (harvestEstimate.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          harvestEstimate,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (fertList.isNotEmpty) ...[
                      const Text('Fertilizer Application Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...fertList.map((item) => _buildItemTile(item, AppTheme.primaryGreen)),
                      const SizedBox(height: 16),
                    ],
                    if (pestList.isNotEmpty) ...[
                      const Text('Pesticide Application Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...pestList.map((item) => _buildItemTile(item, AppTheme.accentGold)),
                      const SizedBox(height: 16),
                    ],
                    if (inspList.isNotEmpty) ...[
                      const Text('Field Inspection Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...inspList.map((item) => _buildItemTile(item, Colors.blueAccent)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(PlanItem item, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(item.description, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          Text(_formatDate(item.date.toIso8601String()), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Planning History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : Column(
              children: [
                // Search bar header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by crop name or acreage...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                ),
                // Stream list
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().getCropPlansStream(_currentUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading history: ${snapshot.error}'));
                      }

                      final plans = snapshot.data ?? [];
                      final filteredPlans = plans.where((plan) {
                        final crop = (plan['cropName'] ?? '').toString().toLowerCase();
                        final acres = (plan['acreage'] ?? '').toString();
                        return crop.contains(_searchQuery) || acres.contains(_searchQuery);
                      }).toList();

                      if (filteredPlans.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 72, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? 'No Saved Crop Plans' : 'No Plans Match Your Search',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Generated crop plans will be saved here automatically.'
                                      : 'Try searching with a different crop name.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPlans.length,
                        itemBuilder: (context, index) {
                          final plan = filteredPlans[index];
                          final planId = plan['planId'] ?? '';
                          final cropName = plan['cropName'] ?? 'Unknown Crop';
                          final acreage = (plan['acreage'] as num?)?.toDouble() ?? 1.0;
                          final plantingDate = _formatDate(plan['plantingDate']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.agriculture_rounded, color: AppTheme.primaryGreen),
                              ),
                              title: Text(
                                '$cropName ($acreage Acres)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  'Sowing Date: $plantingDate',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_rounded, color: AppTheme.primaryGreen),
                                    onPressed: () => _showPlanDetailsModal(plan),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _confirmDelete(planId, cropName),
                                  ),
                                ],
                              ),
                              onTap: () => _showPlanDetailsModal(plan),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
