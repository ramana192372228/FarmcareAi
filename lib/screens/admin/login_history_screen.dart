import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  String _searchQuery = '';
  String _roleFilter = 'ALL';
  String _dateRange = 'ALL'; // 'ALL', 'TODAY', 'WEEKLY', 'MONTHLY'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Login History & Audit Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF Report',
            onPressed: () => _exportPdfReport(context),
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
                        hintText: 'Search user, email, UID...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
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
                        value: _dateRange,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Period: All')),
                          DropdownMenuItem(value: 'TODAY', child: Text('Today')),
                          DropdownMenuItem(value: 'WEEKLY', child: Text('This Week')),
                          DropdownMenuItem(value: 'MONTHLY', child: Text('This Month')),
                        ],
                        onChanged: (val) => setState(() => _dateRange = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Login History Stream
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getLoginHistoryStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                    }

                    var logs = snapshot.data ?? [];

                    // Seed demo logs if empty
                    if (logs.isEmpty) {
                      logs = [
                        {
                          'historyId': 'lh1',
                          'uid': 'FAR1234',
                          'name': 'Rajesh Kumar',
                          'email': 'rajesh@farmcare.ai',
                          'role': 'farmer',
                          'loginTime': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
                          'logoutTime': null,
                          'platform': 'Android',
                          'deviceName': 'Samsung Galaxy M32',
                          'status': 'Active',
                        },
                        {
                          'historyId': 'lh2',
                          'uid': 'SHOP1234',
                          'name': 'Sreenivas Rao',
                          'email': 'shop@srirama.com',
                          'role': 'shop',
                          'loginTime': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
                          'logoutTime': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
                          'platform': 'Web',
                          'deviceName': 'Chrome on Windows',
                          'status': 'Logged Out',
                        },
                        {
                          'historyId': 'lh3',
                          'uid': 'ADMIN01',
                          'name': 'Administrator',
                          'email': 'admin@farmcare.ai',
                          'role': 'admin',
                          'loginTime': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
                          'logoutTime': null,
                          'platform': 'Web',
                          'deviceName': 'Edge on Windows',
                          'status': 'Active',
                        },
                      ];
                    }

                    // Filter
                    logs = logs.where((l) {
                      final name = (l['name'] ?? '').toString().toLowerCase();
                      final email = (l['email'] ?? '').toString().toLowerCase();
                      final uid = (l['uid'] ?? '').toString().toLowerCase();
                      final role = (l['role'] ?? '').toString().toLowerCase();

                      final q = _searchQuery.toLowerCase();
                      final matchesSearch = name.contains(q) || email.contains(q) || uid.contains(q);
                      final matchesRole = _roleFilter == 'ALL' || role == _roleFilter.toLowerCase();
                      return matchesSearch && matchesRole;
                    }).toList();

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final l = logs[index];
                        final status = l['status'] ?? 'Logged Out';
                        final isActive = status == 'Active';

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.grey.shade200,
                              child: Icon(
                                l['platform'] == 'Web' ? Icons.laptop_rounded : Icons.phone_android_rounded,
                                color: isActive ? AppTheme.primaryGreen : Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text('${l['name']} (${(l['role'] ?? '').toString().toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text('UID: ${l['uid']} • 💻 Device: ${l['deviceName']}'),
                                Text('Login: ${_formatTime(l['loginTime'])} • Logout: ${_formatTime(l['logoutTime'])}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppTheme.primaryGreen : Colors.grey[700])),
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

  Future<void> _exportPdfReport(BuildContext context) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('FarmCare AI - User Login History Audit Report', style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toString()}'),
            pw.SizedBox(height: 16),
            pw.Text('Comprehensive log of authentications across Android and Web platforms.'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  String _formatTime(dynamic val) {
    if (val == null) return 'Active';
    if (val is String) {
      final dt = DateTime.tryParse(val);
      if (dt != null) return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Recent';
  }
}
