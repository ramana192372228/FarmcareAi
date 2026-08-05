import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../screens/farmer_dashboard.dart';
import '../screens/shop/shop_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/farmer/weather_screen.dart';
import '../screens/farmer/crop_planning_screen.dart';
import '../screens/farmer/fertilizer_screen.dart';
import '../screens/farmer/soil_health_screen.dart';
import '../screens/farmer/ai_agronomist_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/farmer/my_farm_screen.dart';
import '../screens/farmer/machinery_screen.dart';
import '../screens/shop/shop_machinery_screen.dart';
import '../screens/farmer/marketplace_screen.dart';
import '../screens/farmer/community_screen.dart';
import '../screens/farmer/notifications_screen.dart';
import '../screens/farmer/profile_screen.dart';
import '../screens/shop/shop_notifications_screen.dart';
import '../screens/shop/shop_profile_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/role_screen.dart';

enum WebTab {
  dashboard,
  weather,
  cropPlanning,
  fertilizer,
  soilHealth,
  aiAgronomist,
  scanner,
  myFarm,
  machinery,
  marketplace,
  community,
  notifications,
  profile,
  settings,
}

class WebLayoutShell extends StatefulWidget {
  final Widget child;
  final WebTab currentTab;
  final String role;

  const WebLayoutShell({
    super.key,
    required this.child,
    this.currentTab = WebTab.dashboard,
    this.role = 'farmer',
  });

  @override
  State<WebLayoutShell> createState() => _WebLayoutShellState();
}

class _WebLayoutShellState extends State<WebLayoutShell> {
  late WebTab _activeTab;
  String _userRole = 'farmer';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.currentTab;
    _userRole = widget.role;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final auth = AuthService();
    final role = await auth.getLoggedUserRole() ?? 'farmer';
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  void _navigateToTab(WebTab tab) {
    if (tab == _activeTab) return;
    setState(() => _activeTab = tab);

    Widget destination;
    switch (tab) {
      case WebTab.dashboard:
        if (_userRole == 'shop') {
          destination = const ShopDashboard();
        } else if (_userRole == 'admin') {
          destination = const AdminDashboard();
        } else {
          destination = const FarmerDashboard();
        }
        break;
      case WebTab.weather:
        destination = const WeatherScreen();
        break;
      case WebTab.cropPlanning:
        destination = const CropPlanningScreen();
        break;
      case WebTab.fertilizer:
        destination = const FertilizerScreen();
        break;
      case WebTab.soilHealth:
        destination = const SoilHealthScreen();
        break;
      case WebTab.aiAgronomist:
        destination = const AiAgronomistScreen();
        break;
      case WebTab.scanner:
        destination = const ScannerScreen();
        break;
      case WebTab.myFarm:
        destination = const MyFarmScreen();
        break;
      case WebTab.machinery:
        if (_userRole == 'shop') {
          destination = const ShopMachineryScreen();
        } else {
          destination = const MachineryScreen();
        }
        break;
      case WebTab.marketplace:
        destination = const MarketplaceScreen();
        break;
      case WebTab.community:
        destination = const CommunityScreen();
        break;
      case WebTab.notifications:
        if (_userRole == 'shop') {
          destination = const ShopNotificationsScreen();
        } else {
          destination = const NotificationsScreen();
        }
        break;
      case WebTab.profile:
      case WebTab.settings:
        if (_userRole == 'shop') {
          destination = const ShopProfileScreen();
        } else if (_userRole == 'admin') {
          destination = const AdminProfileScreen();
        } else {
          destination = const FarmerProfileScreen();
        }
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => WebLayoutShell(
          currentTab: tab,
          role: _userRole,
          child: destination,
        ),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = kIsWeb || screenWidth >= 900;

    // Mobile view fallback directly returns child
    if (!isDesktop) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Top Desktop App Bar
          _buildTopBar(),
          // Main Body: Left Sidebar + Content Area
          Expanded(
            child: Row(
              children: [
                // Left Desktop Sidebar
                _buildSidebar(),
                // Main Content Display Area
                Expanded(
                  child: Container(
                    color: AppTheme.backgroundLight,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1300),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo & Application Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FarmCare AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Smart Agriculture Platform',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Notifications Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () => _navigateToTab(WebTab.notifications),
          ),
          const SizedBox(width: 12),
          // Role & Profile Badge
          InkWell(
            onTap: () => _navigateToTab(WebTab.profile),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 18, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _userRole.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Logout Button
          TextButton.icon(
            onPressed: () async {
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
            label: const Text('Logout', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    List<_SidebarItemData> items;
    if (_userRole == 'admin') {
      items = [
        _SidebarItemData(WebTab.dashboard, 'Admin Control Center', Icons.admin_panel_settings_rounded),
        _SidebarItemData(WebTab.marketplace, 'Marketplace Catalog', Icons.storefront_rounded),
        _SidebarItemData(WebTab.community, 'Community Forum', Icons.forum_rounded),
        _SidebarItemData(WebTab.notifications, 'Advisory Broadcasts', Icons.campaign_rounded),
        _SidebarItemData(WebTab.profile, 'Admin Profile', Icons.person_rounded),
      ];
    } else if (_userRole == 'shop') {
      items = [
        _SidebarItemData(WebTab.dashboard, 'Shop Dashboard', Icons.dashboard_rounded),
        _SidebarItemData(WebTab.marketplace, 'Inventory Catalog', Icons.inventory_2_rounded),
        _SidebarItemData(WebTab.machinery, 'Machinery Rentals', Icons.precision_manufacturing_rounded),
        _SidebarItemData(WebTab.community, 'Community Forum', Icons.forum_rounded),
        _SidebarItemData(WebTab.notifications, 'Shop Alerts', Icons.notifications_active_rounded),
        _SidebarItemData(WebTab.profile, 'Business Profile', Icons.storefront_rounded),
      ];
    } else {
      items = [
        _SidebarItemData(WebTab.dashboard, 'Dashboard', Icons.dashboard_rounded),
        _SidebarItemData(WebTab.weather, 'Weather', Icons.cloud_rounded),
        _SidebarItemData(WebTab.cropPlanning, 'Crop Planning', Icons.calendar_month_rounded),
        _SidebarItemData(WebTab.fertilizer, 'Fertilizer Advisor', Icons.science_rounded),
        _SidebarItemData(WebTab.soilHealth, 'Soil Health', Icons.landscape_rounded),
        _SidebarItemData(WebTab.aiAgronomist, 'AI Agronomist', Icons.psychology_rounded),
        _SidebarItemData(WebTab.scanner, 'Disease Scanner', Icons.center_focus_strong_rounded),
        _SidebarItemData(WebTab.myFarm, 'My Farm', Icons.agriculture_rounded),
        _SidebarItemData(WebTab.machinery, 'Farm Machinery', Icons.precision_manufacturing_rounded),
        _SidebarItemData(WebTab.marketplace, 'Marketplace', Icons.storefront_rounded),
        _SidebarItemData(WebTab.community, 'Community', Icons.forum_rounded),
        _SidebarItemData(WebTab.notifications, 'Notifications', Icons.notifications_active_rounded),
        _SidebarItemData(WebTab.profile, 'Profile', Icons.person_rounded),
      ];
    }

    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.tab == _activeTab;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _navigateToTab(item.tab),
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  final WebTab tab;
  final String label;
  final IconData icon;
  _SidebarItemData(this.tab, this.label, this.icon);
}
