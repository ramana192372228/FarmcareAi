import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _searchQuery = '';
  String _categoryFilter = 'ALL';

  final List<String> _categories = [
    'ALL',
    'AUTHENTICATION',
    'ORDER',
    'MARKETPLACE',
    'CROP_PLANNING',
    'SOIL_HEALTH',
    'AI_DIAGNOSTICS',
    'MACHINERY',
    'NOTIFICATION',
    'ADMIN',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('System Audit Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export Audit Report',
            onPressed: () => _exportPdfReport(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search & Category Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search audit action, user, details...',
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
                        value: _categoryFilter,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
                        onChanged: (val) => setState(() => _categoryFilter = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Audit Logs Stream
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getAuditLogsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                    }

                    var logs = snapshot.data ?? [];

                    // Seed demo logs if empty
                    if (logs.isEmpty) {
                      logs = [
                        {
                          'logId': 'al1',
                          'userId': 'FAR1234',
                          'userName': 'Rajesh Kumar',
                          'action': 'Created Crop Plan',
                          'category': 'CROP_PLANNING',
                          'details': 'Planned 5 Acres Cotton H-4 for Kharif Season',
                          'timestamp': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
                        },
                        {
                          'logId': 'al2',
                          'userId': 'SHOP1234',
                          'userName': 'Sreenivas Rao',
                          'action': 'Added Marketplace Product',
                          'category': 'MARKETPLACE',
                          'details': 'Product: Basmati Rice Seeds Super-1',
                          'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
                        },
                        {
                          'logId': 'al3',
                          'userId': 'ADMIN01',
                          'userName': 'Administrator',
                          'action': 'Broadcast Weather Warning Alert',
                          'category': 'NOTIFICATION',
                          'details': 'Sent heavy rainfall alert to Guntur & Krishna farmers.',
                          'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
                        },
                        {
                          'logId': 'al4',
                          'userId': 'FAR5678',
                          'userName': 'Venkateswarlu Naidu',
                          'action': 'AI Disease Diagnosis Scan',
                          'category': 'AI_DIAGNOSTICS',
                          'details': 'Detected Leaf Blight (Confidence 96%)',
                          'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
                        },
                      ];
                    }

                    // Filter
                    logs = logs.where((l) {
                      final act = (l['action'] ?? '').toString().toLowerCase();
                      final user = (l['userName'] ?? '').toString().toLowerCase();
                      final det = (l['details'] ?? '').toString().toLowerCase();
                      final cat = (l['category'] ?? '').toString();

                      final q = _searchQuery.toLowerCase();
                      final matchesSearch = act.contains(q) || user.contains(q) || det.contains(q);
                      final matchesCat = _categoryFilter == 'ALL' || cat == _categoryFilter;
                      return matchesSearch && matchesCat;
                    }).toList();

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final l = logs[index];
                        final cat = l['category'] as String? ?? 'GENERAL';

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(cat).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getCategoryIcon(cat), color: _getCategoryColor(cat), size: 20),
                            ),
                            title: Text(l['action'] as String? ?? 'Action', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text('By: ${l['userName']} (ID: ${l['userId']})'),
                                Text(l['details'] as String? ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                const SizedBox(height: 4),
                                Text(_formatTime(l['timestamp']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'AUTHENTICATION':
        return Icons.lock_rounded;
      case 'ORDER':
        return Icons.shopping_bag_rounded;
      case 'MARKETPLACE':
        return Icons.storefront_rounded;
      case 'CROP_PLANNING':
        return Icons.calendar_month_rounded;
      case 'SOIL_HEALTH':
        return Icons.landscape_rounded;
      case 'AI_DIAGNOSTICS':
        return Icons.center_focus_strong_rounded;
      case 'MACHINERY':
        return Icons.agriculture_rounded;
      case 'NOTIFICATION':
        return Icons.campaign_rounded;
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'AUTHENTICATION':
        return Colors.blue;
      case 'ORDER':
        return AppTheme.primaryGreen;
      case 'MARKETPLACE':
        return AppTheme.accentGold;
      case 'CROP_PLANNING':
        return Colors.teal;
      case 'SOIL_HEALTH':
        return Colors.brown;
      case 'AI_DIAGNOSTICS':
        return Colors.purple;
      case 'MACHINERY':
        return Colors.deepOrange;
      case 'NOTIFICATION':
        return Colors.pink;
      case 'ADMIN':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportPdfReport(BuildContext context) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('FarmCare AI - System Audit Log Report', style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now().toString()}'),
            pw.SizedBox(height: 16),
            pw.Text('Automated system event log and administrative actions breakdown.'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  String _formatTime(dynamic val) {
    if (val is String) {
      final dt = DateTime.tryParse(val);
      if (dt != null) return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Recent';
  }
}
