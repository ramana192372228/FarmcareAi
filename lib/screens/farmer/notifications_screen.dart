import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notification> _notifications = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final auth = AuthService();
    _userId = await auth.getLoggedUserPhone();
    final String userIdQuery = _userId ?? 'ALL';

    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('read_notifications_ids_$userIdQuery') ?? [];

    bool loadedFromFirestore = false;
    List<Map<String, dynamic>> fetchedNotifs = [];

    try {
      debugPrint('[NOTIFICATIONS_SCREEN] Loading notifications from Firestore first...');
      fetchedNotifs = await FirestoreService().getNotifications(userIdQuery);
      
      if (fetchedNotifs.isNotEmpty) {
        loadedFromFirestore = true;
        // Save/Sync to SharedPreferences cache
        final serializableNotifs = fetchedNotifs.map((item) {
          final copy = Map<String, dynamic>.from(item);
          if (copy['createdAt'] is Timestamp) {
            copy['createdAt'] = (copy['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          return copy;
        }).toList();
        await prefs.setString('notifications_cache', jsonEncode(serializableNotifs));
        debugPrint('[NOTIFICATIONS_SCREEN] Loaded ${fetchedNotifs.length} notifications from Firestore.');
      } else {
        // Seed Firestore if empty
        debugPrint('[NOTIFICATIONS_SCREEN] Firestore notifications are empty. Seeding defaults...');
        await _seedNotificationsToFirestore();
        fetchedNotifs = await FirestoreService().getNotifications(userIdQuery);
        if (fetchedNotifs.isNotEmpty) {
          loadedFromFirestore = true;
          final serializableNotifs = fetchedNotifs.map((item) {
            final copy = Map<String, dynamic>.from(item);
            if (copy['createdAt'] is Timestamp) {
              copy['createdAt'] = (copy['createdAt'] as Timestamp).millisecondsSinceEpoch;
            }
            return copy;
          }).toList();
          await prefs.setString('notifications_cache', jsonEncode(serializableNotifs));
        }
      }
    } catch (e) {
      debugPrint('[NOTIFICATIONS_SCREEN] Error loading notifications from Firestore: $e');
    }

    if (!loadedFromFirestore) {
      debugPrint('[NOTIFICATIONS_SCREEN] Falling back to SharedPreferences cache.');
      final cachedJson = prefs.getString('notifications_cache');
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as List;
          fetchedNotifs = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        } catch (e) {
          debugPrint('[NOTIFICATIONS_SCREEN] Error decoding cached notifications: $e');
        }
      } else {
        // Seed locally if no cache
        fetchedNotifs = _getDefaultMockNotificationsData();
        final serializableNotifs = fetchedNotifs.map((item) {
          final copy = Map<String, dynamic>.from(item);
          if (copy['createdAt'] is Timestamp) {
            copy['createdAt'] = (copy['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          return copy;
        }).toList();
        await prefs.setString('notifications_cache', jsonEncode(serializableNotifs));
      }
    }

    // Map fetchedNotifs to local notifications
    setState(() {
      _notifications.clear();
      for (final item in fetchedNotifs) {
        final id = item['notificationId'] ?? '';
        final title = item['title'] ?? '';
        final message = item['message'] ?? '';
        final typeStr = item['type'] ?? 'advisory';
        final type = NotifType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => NotifType.advisory,
        );
        
        dynamic rawCreatedAt = item['createdAt'];
        int ms = 0;
        if (rawCreatedAt is Timestamp) {
          ms = rawCreatedAt.millisecondsSinceEpoch;
        } else if (rawCreatedAt is int) {
          ms = rawCreatedAt;
        } else if (rawCreatedAt is String) {
          ms = DateTime.tryParse(rawCreatedAt)?.millisecondsSinceEpoch ?? 0;
        }
        
        final timeStr = _formatTimestamp(ms);
        final isUnread = !readList.contains(id);

        _notifications.add(_Notification(id, title, message, timeStr, type, isUnread: isUnread));
      }
      _isLoading = false;
    });
  }

  Future<void> _seedNotificationsToFirestore() async {
    final defaultData = _getDefaultMockNotificationsData();
    final firestore = FirestoreService();
    for (final notif in defaultData) {
      final id = notif['notificationId'];
      await firestore.saveNotification(id, notif);
    }

    final key = 'read_notifications_ids_${_userId ?? 'ALL'}';
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(key)) {
      final defaultReadIds = [
        'notif_seed_4',
        'notif_seed_5',
        'notif_seed_6',
        'notif_seed_7',
        'notif_seed_8',
        'notif_seed_9',
        'notif_seed_10',
      ];
      await prefs.setStringList(key, defaultReadIds);
    }
  }

  List<Map<String, dynamic>> _getDefaultMockNotificationsData() {
    final now = DateTime.now();
    return [
      {
        'notificationId': 'notif_seed_1',
        'title': '⚠️ Heavy Rain Alert',
        'message': 'Moderate to heavy rainfall expected in your district for next 2 days. Avoid pesticide spraying. Secure stored produce.',
        'type': 'weather',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_2',
        'title': '🌾 PM-KISAN Installment',
        'message': '₹2,000 PM-KISAN installment will be credited to your linked bank account within 3 working days.',
        'type': 'scheme',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_3',
        'title': '📈 Cotton Price Rise',
        'message': 'Cotton MCX rate increased by ₹320/quintal today. Current APMC rate: ₹6,560/q. Good time to sell.',
        'type': 'market',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_4',
        'title': '🐛 Pest Alert: Bollworm',
        'message': 'Bollworm (Helicoverpa armigera) outbreak reported in 3 districts nearby. Pheromone trap count exceeds 8/week — action required.',
        'type': 'pest',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_5',
        'title': '💧 Irrigation Advisory',
        'message': 'Soil moisture levels are adequate after last week\'s rain. Skip irrigation for next 4–5 days for cotton fields.',
        'type': 'advisory',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_6',
        'title': '📋 Soil Testing Camp',
        'message': 'Free soil testing camp organized by KVK Guntur on 18th June. Bring 500g soil sample from each field block.',
        'type': 'scheme',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_7',
        'title': '🌡️ Heatwave Warning',
        'message': 'Maximum temperature expected to rise above 42°C next week. Apply mulch and irrigate in early morning to reduce crop heat stress.',
        'type': 'weather',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_8',
        'title': '🌱 Crop Planning Reminder',
        'message': 'Kharif sowing season begins next month. Ensure seed procurement and soil preparation by 15th July.',
        'type': 'advisory',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_9',
        'title': '📊 Weekly Market Report',
        'message': 'Tomato: ₹18/kg (+15%). Rice: ₹2,183/q (stable). Maize: ₹1,890/q (-2%). Groundnut: ₹5,250/q (+3%).',
        'type': 'market',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'isGlobal': true,
        'userId': 'ALL',
      },
      {
        'notificationId': 'notif_seed_10',
        'title': '✅ PMFBY Registration Open',
        'message': 'Kharif 2026 crop insurance registration deadline: 31st July. Contact your bank or CSC center today.',
        'type': 'scheme',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'isGlobal': true,
        'userId': 'ALL',
      },
    ];
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      if (difference.inMinutes <= 0) return 'Just now';
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? "s" : ""} ago';
    }
  }

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  void _markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'read_notifications_ids_${_userId ?? 'ALL'}';
    final readList = prefs.getStringList(key) ?? [];

    setState(() {
      for (final n in _notifications) {
        n.isUnread = false;
        if (!readList.contains(n.id)) {
          readList.add(n.id);
        }
      }
    });

    await prefs.setStringList(key, readList);
  }

  void _markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'read_notifications_ids_${_userId ?? 'ALL'}';
    final readList = prefs.getStringList(key) ?? [];
    if (!readList.contains(id)) {
      readList.add(id);
      await prefs.setStringList(key, readList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_unreadCount > 0 && !_isLoading)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : Column(
                children: [
                  // Filter tabs
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        if (_unreadCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(20)),
                            child: Text('$_unreadCount New', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                        ],
                        ...NotifType.values.map((t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _typeColor(t).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(_typeLabel(t), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _typeColor(t))),
                          ),
                        )),
                      ],
                    ),
                  ),
                  // Notifications list
                  Expanded(
                    child: _notifications.isEmpty
                        ? const Center(child: Text('No notifications found.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _notifications.length,
                            itemBuilder: (ctx, i) => _notifCard(_notifications[i]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _notifCard(_Notification n) {
    final color = _typeColor(n.type);
    return GestureDetector(
      onTap: () {
        if (n.isUnread) {
          setState(() {
            n.isUnread = false;
          });
          _markAsRead(n.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isUnread ? color.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: n.isUnread ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.12), width: n.isUnread ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(_typeIcon(n.type), color: color, size: 20),
                ),
                if (n.isUnread)
                  Positioned(top: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isUnread ? FontWeight.bold : FontWeight.w600, color: Colors.black87))),
                      Text(n.time, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(n.body, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.35)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_typeLabel(n.type), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(NotifType t) {
    switch (t) {
      case NotifType.weather: return Colors.blueAccent;
      case NotifType.market: return AppTheme.accentGold;
      case NotifType.pest: return Colors.redAccent;
      case NotifType.advisory: return AppTheme.primaryGreen;
      case NotifType.scheme: return Colors.purple;
    }
  }

  IconData _typeIcon(NotifType t) {
    switch (t) {
      case NotifType.weather: return Icons.wb_cloudy_rounded;
      case NotifType.market: return Icons.trending_up_rounded;
      case NotifType.pest: return Icons.bug_report_rounded;
      case NotifType.advisory: return Icons.tips_and_updates_rounded;
      case NotifType.scheme: return Icons.account_balance_rounded;
    }
  }

  String _typeLabel(NotifType t) {
    switch (t) {
      case NotifType.weather: return 'Weather';
      case NotifType.market: return 'Market';
      case NotifType.pest: return 'Pest Alert';
      case NotifType.advisory: return 'Advisory';
      case NotifType.scheme: return 'Scheme';
    }
  }
}

enum NotifType { weather, market, pest, advisory, scheme }

class _Notification {
  final String id;
  final String title, body, time;
  final NotifType type;
  bool isUnread;
  _Notification(this.id, this.title, this.body, this.time, this.type, {this.isUnread = false});
}
