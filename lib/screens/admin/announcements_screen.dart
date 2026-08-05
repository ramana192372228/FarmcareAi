import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _targetAudience = 'ALL'; // 'ALL', 'FARMERS', 'SHOPS'
  String _alertType = 'Weather Alert'; // 'Weather Alert', 'Government Schemes', 'Cyclone Warning', 'Disease Alert', 'Market Price Alert', 'General Announcement'

  final List<String> _audiences = ['ALL', 'FARMERS', 'SHOPS'];
  final List<String> _types = [
    'Weather Alert',
    'Government Schemes',
    'Cyclone Warning',
    'Disease Alert',
    'Market Price Alert',
    'General Announcement',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _broadcastAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      try {
        final notifData = {
          'title': title,
          'message': body,
          'target': _targetAudience,
          'type': _alertType,
          'sender': 'ADMIN',
          'isRead': false,
        };

        await FirestoreService().createNotification(notifData);
        await FirestoreService().logAuditEvent(
          userId: 'ADMIN',
          action: 'Broadcasted Notification',
          category: 'NOTIFICATION',
          details: 'Type: $_alertType, Target: $_targetAudience, Title: $title',
        );

        _titleController.clear();
        _bodyController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification broadcasted to targeted users!'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to broadcast notification: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notification Broadcast Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Broadcast Hyper-Local Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const SizedBox(height: 4),
                Text('Send weather advisories, pest outbreak warnings, or government subsidies to users.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 20),

                // Target Audience & Type Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _targetAudience,
                        decoration: InputDecoration(
                          labelText: 'Target Audience',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: _audiences.map((a) => DropdownMenuItem(value: a, child: Text('Target: $a'))).toList(),
                        onChanged: (val) => setState(() => _targetAudience = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _alertType,
                        decoration: InputDecoration(
                          labelText: 'Alert Category',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => setState(() => _alertType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Broadcast Headline / Title',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter headline' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bodyController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Detailed Advisory Body & Action Steps',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter advisory text' : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _broadcastAnnouncement,
                    icon: const Icon(Icons.campaign_rounded, color: Colors.white),
                    label: const Text('BROADCAST NOTIFICATION NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(height: 32),

                // Broadcast History Stream
                const Text('Broadcast History & Audit Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const SizedBox(height: 12),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getNotificationsStream('ADMIN'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                    }

                    var logs = snapshot.data ?? [];

                    if (logs.isEmpty) {
                      logs = [
                        {
                          'id': 'n1',
                          'title': 'Heavy Rainfall Alert in Guntur & Krishna',
                          'message': 'High precipitation expected. Delay nitrogen application to avoid leaching.',
                          'type': 'Weather Alert',
                          'target': 'ALL',
                        },
                        {
                          'id': 'n2',
                          'title': 'PM-KISAN 17th Installment Scheme Released',
                          'message': 'Eligible farmers can verify DBT payment status in portal.',
                          'type': 'Government Schemes',
                          'target': 'FARMERS',
                        },
                      ];
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final n = logs[index];

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_active_rounded, color: AppTheme.accentGold, size: 20),
                            ),
                            title: Text(n['title'] as String? ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text('Type: ${n['type']} • Target: ${n['target']}'),
                                Text(n['message'] as String? ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
