import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  String _roleFilter = 'ALL';
  String _statusFilter = 'ALL';
  bool _isLoading = true;

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await FirestoreService().getAllUsers();
      _users = list;

      // Seed fallback users if Firestore collection is empty
      if (_users.isEmpty) {
        _users = [
          {
            'uid': 'FAR101',
            'name': 'Rajesh Kumar',
            'email': 'rajesh@farmcare.ai',
            'phone': '9876543210',
            'role': 'farmer',
            'district': 'Guntur',
            'status': 'Active',
            'platform': 'Android',
            'createdDate': '2026-01-15',
            'lastLogin': '2026-08-05 09:30',
          },
          {
            'uid': 'SHOP102',
            'name': 'Kalyan Seed Agency',
            'email': 'kalyan@seeds.com',
            'phone': '9000122233',
            'role': 'shop',
            'district': 'Krishna',
            'status': 'Active',
            'platform': 'Web',
            'createdDate': '2026-02-10',
            'lastLogin': '2026-08-05 08:15',
          },
          {
            'uid': 'ADMIN01',
            'name': 'System Administrator',
            'email': 'admin@farmcare.ai',
            'phone': '9988776655',
            'role': 'admin',
            'district': 'Amaravati',
            'status': 'Active',
            'platform': 'Web',
            'createdDate': '2026-01-01',
            'lastLogin': '2026-08-05 10:00',
          },
          {
            'uid': 'FAR104',
            'name': 'Kondal Rao',
            'email': 'kondal@gmail.com',
            'phone': '7776665544',
            'role': 'farmer',
            'district': 'Prakasam',
            'status': 'Suspended',
            'platform': 'Android',
            'createdDate': '2026-03-20',
            'lastLogin': '2026-07-28 14:20',
          },
        ];
      }
    } catch (e) {
      debugPrint('[USER_MGMT] Error loading users: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUserStatus(String uid, String currentStatus) async {
    final newStatus = currentStatus == 'Active' ? 'Suspended' : 'Active';
    try {
      await FirestoreService().updateUserStatus(uid, newStatus);
      await FirestoreService().logAuditEvent(
        userId: 'ADMIN',
        action: 'Toggled User Status',
        category: 'ADMIN',
        details: 'User $uid updated to $newStatus',
      );
      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _deleteUser(String uid, String name) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User Account?'),
        content: Text('Are you sure you want to permanently delete $name ($uid)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteUserDoc(uid);
              await FirestoreService().logAuditEvent(
                userId: 'ADMIN',
                action: 'Deleted User',
                category: 'ADMIN',
                details: 'Deleted user $name ($uid)',
              );
              _loadUsers();
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
    final filtered = _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      final uid = (u['uid'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      final status = (u['status'] ?? 'Active').toString().toLowerCase();

      final q = _searchQuery.toLowerCase();
      final matchesQ = name.contains(q) || email.contains(q) || phone.contains(q) || uid.contains(q);
      final matchesRole = _roleFilter == 'ALL' || role == _roleFilter.toLowerCase();
      final matchesStatus = _statusFilter == 'ALL' || status == _statusFilter.toLowerCase();

      return matchesQ && matchesRole && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('SQL User Management Table', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search & Filter Header
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search name, email, phone, UID...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _roleFilter,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Role: All')),
                          DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                          DropdownMenuItem(value: 'shop', child: Text('Shop Owner')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (val) => setState(() => _roleFilter = val!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Status: All')),
                          DropdownMenuItem(value: 'Active', child: Text('Active')),
                          DropdownMenuItem(value: 'Suspended', child: Text('Suspended')),
                        ],
                        onChanged: (val) => setState(() => _statusFilter = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SQL Data Table List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.primaryGreen.withValues(alpha: 0.1)),
                            dataRowMaxHeight: 64,
                            columns: const [
                              DataColumn(label: Text('UID', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('District', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Platform', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filtered.map((u) {
                              final status = u['status'] ?? 'Active';
                              final isActive = status == 'Active';

                              return DataRow(
                                cells: [
                                  DataCell(Text(u['uid'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataCell(Text(u['name'] ?? 'User')),
                                  DataCell(Text((u['role'] ?? '').toString().toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                  DataCell(Text(u['phone'] ?? '')),
                                  DataCell(Text(u['district'] ?? 'N/A')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppTheme.primaryGreen : Colors.redAccent)),
                                    ),
                                  ),
                                  DataCell(Text(u['platform'] ?? 'Android')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, color: isActive ? Colors.orange.shade800 : AppTheme.primaryGreen, size: 20),
                                          onPressed: () => _toggleUserStatus(u['uid'], status),
                                          tooltip: isActive ? 'Disable User' : 'Enable User',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                          onPressed: () => _deleteUser(u['uid'], u['name'] ?? 'User'),
                                          tooltip: 'Delete User',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
