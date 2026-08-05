import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ShopNotificationsScreen extends StatefulWidget {
  const ShopNotificationsScreen({super.key});

  @override
  State<ShopNotificationsScreen> createState() => _ShopNotificationsScreenState();
}

class _ShopNotificationsScreenState extends State<ShopNotificationsScreen> {
  String _shopId = 'SHOP1234';
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final phone = await AuthService().getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      setState(() => _shopId = phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark All as Read',
            onPressed: () async {
              await FirestoreService().markAllNotificationsRead(_shopId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Notifications'),
                    selected: !_showOnlyUnread,
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: !_showOnlyUnread ? AppTheme.primaryGreen : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _showOnlyUnread = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unread Only'),
                    selected: _showOnlyUnread,
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _showOnlyUnread ? AppTheme.primaryGreen : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _showOnlyUnread = true),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Notifications List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: FirestoreService().getNotifications(_shopId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                  }

                  var notifs = snapshot.data ?? [];

                  // Seed initial system notifications for Shop Owner if empty
                  if (notifs.isEmpty) {
                    notifs = [
                      {
                        'notificationId': 'n1',
                        'title': '📦 New Seed Order Received',
                        'message': 'Farmer Rajesh Kumar placed order #ORD8901 for 2x Hybrid Cotton Seeds.',
                        'type': 'ORDER',
                        'isRead': false,
                        'createdAt': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
                      },
                      {
                        'notificationId': 'n2',
                        'title': '⚠️ Low Stock Alert',
                        'message': 'Basmati Rice Seeds Super-1 stock dropped to 5 packs.',
                        'type': 'LOW_STOCK',
                        'isRead': false,
                        'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
                      },
                      {
                        'notificationId': 'n3',
                        'title': '🚜 Machinery Booking Request',
                        'message': 'Venkateswarlu Naidu requested Mahindra Tractor for 3 days.',
                        'type': 'MACHINERY',
                        'isRead': true,
                        'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
                      },
                      {
                        'notificationId': 'n4',
                        'title': '🌾 Crop Sale Offer',
                        'message': 'New Cotton sale offer (1200kg @ ₹62/kg) submitted in Ramapuram.',
                        'type': 'PROCUREMENT',
                        'isRead': true,
                        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
                      },
                      {
                        'notificationId': 'n5',
                        'title': '📢 Admin Announcement',
                        'message': 'Subsidized fertilizer quota for Q3 is now open for distributor updates.',
                        'type': 'ANNOUNCEMENT',
                        'isRead': true,
                        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
                      },
                    ];
                  }

                  if (_showOnlyUnread) {
                    notifs = notifs.where((n) => (n['isRead'] as bool? ?? false) == false).toList();
                  }

                  if (notifs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text('No Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('You are all caught up!', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      final isRead = n['isRead'] as bool? ?? false;
                      final type = n['type'] as String? ?? 'GENERAL';

                      return Card(
                        color: isRead ? Colors.white : AppTheme.primaryGreen.withValues(alpha: 0.04),
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isRead ? Colors.grey.shade200 : AppTheme.primaryGreen.withValues(alpha: 0.3),
                            width: isRead ? 1 : 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () async {
                            if (!isRead && n['notificationId'] != null) {
                              await FirestoreService().markNotificationRead(n['notificationId']);
                              setState(() => n['isRead'] = true);
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(type).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getNotificationIcon(type), color: _getNotificationColor(type), size: 22),
                          ),
                          title: Text(
                            n['title'] as String? ?? 'Notification',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n['message'] as String? ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(n['createdAt']),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? const CircleAvatar(radius: 5, backgroundColor: AppTheme.primaryGreen)
                              : null,
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
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'ORDER':
        return Icons.shopping_bag_rounded;
      case 'LOW_STOCK':
        return Icons.warning_amber_rounded;
      case 'MACHINERY':
        return Icons.agriculture_rounded;
      case 'PROCUREMENT':
        return Icons.scale_rounded;
      case 'ANNOUNCEMENT':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'ORDER':
        return Colors.blue;
      case 'LOW_STOCK':
        return Colors.redAccent;
      case 'MACHINERY':
        return Colors.purple;
      case 'PROCUREMENT':
        return AppTheme.accentGold;
      case 'ANNOUNCEMENT':
        return AppTheme.primaryGreen;
      default:
        return Colors.teal;
    }
  }

  String _formatTime(dynamic val) {
    if (val is String) {
      final dt = DateTime.tryParse(val);
      if (dt != null) return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Recent';
  }
}
