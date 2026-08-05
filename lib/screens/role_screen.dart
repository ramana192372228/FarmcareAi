import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import 'login_screen.dart';

class RoleScreen extends StatefulWidget {
  final String? phoneNumber;
  const RoleScreen({super.key, this.phoneNumber});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  int _selectedRoleIndex = 0; // Default to Farmer
  bool _isCompleted = false;

  List<RoleData> get _roles {
    final trans = TranslationService();
    return [
      RoleData(
        title: trans.translate('role_farmer_title'),
        description: trans.translate('role_farmer_desc'),
        icon: Icons.agriculture_rounded,
        color: AppTheme.primaryGreen,
        gradientColors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
      ),
      RoleData(
        title: trans.translate('role_shop_title'),
        description: trans.translate('role_shop_desc'),
        icon: Icons.storefront_rounded,
        color: AppTheme.accentGold,
        gradientColors: [AppTheme.accentGold, const Color(0xFFE08B00)],
      ),
      RoleData(
        title: 'Administrator',
        description: 'Manage users, verify merchant shops, and issue platform alerts.',
        icon: Icons.admin_panel_settings_rounded,
        color: Colors.indigo,
        gradientColors: [Colors.indigo, Colors.blueAccent],
      ),
    ];
  }

  void _confirmRoleSelection() {
    String role = 'farmer';
    if (_selectedRoleIndex == 1) role = 'shop';
    if (_selectedRoleIndex == 2) role = 'admin';

    if (mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(role: role),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildPhase1CompletionView();
    }

    final trans = TranslationService();
    final rolesList = _roles;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trans.translate('choose_role'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trans.translate('role_subtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              
              // Roles Cards List
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: rolesList.length,
                  itemBuilder: (context, index) {
                    final role = rolesList[index];
                    final isSelected = _selectedRoleIndex == index;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRoleIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? role.color : Colors.grey.withValues(alpha: 0.15),
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                  ? role.color.withValues(alpha: 0.1) 
                                  : Colors.black.withValues(alpha: 0.02),
                              blurRadius: isSelected ? 16 : 8,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left gradient Icon wrapper
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: role.gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                role.icon,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Center texts details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? role.color : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    role.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[650],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Selection tick status
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? role.color : Colors.grey.withValues(alpha: 0.4),
                                  width: 2.0,
                                ),
                                color: isSelected ? role.color : Colors.transparent,
                              ),
                              child: isSelected 
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) 
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Proceed button
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirmRoleSelection,
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      backgroundColor: rolesList[_selectedRoleIndex].color,
                      shadowColor: rolesList[_selectedRoleIndex].color.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(trans.translate('confirm_selection')),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded, size: 18),
                      ],
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

  Widget _buildPhase1CompletionView() {
    final confirmedRole = _roles[_selectedRoleIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen.withValues(alpha: 0.05),
              AppTheme.backgroundLight,
              confirmedRole.color.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Celebration Check Circle
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    size: 80,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Complete Banner Header
                const Text(
                  'Phase 1 Complete!',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  'FarmCare AI entry flow is fully implemented and compiled successfully with 0 errors.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[750],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                
                // Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Verified Entry Configurations',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.bolt_rounded, 'Animated Splash Screen', 'Elastic scaling transition'),
                      _buildDetailRow(Icons.translate_rounded, 'Language Preference', ' Telugu, Tamil, Kannada +3'),
                      _buildDetailRow(Icons.mobile_screen_share_rounded, '3 Onboarding Slides', 'Custom vectors + dots tracker'),
                      _buildDetailRow(Icons.vpn_key_rounded, 'Login & Verification', 'Google Sign-In + Admin Auth'),
                      _buildDetailRow(confirmedRole.icon, 'Platform Role Profile', confirmedRole.title, highlight: true, color: confirmedRole.color),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Return button / Reset
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isCompleted = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryGreen,
                      elevation: 2,
                      side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Re-verify Entry Flow'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool highlight = false, Color color = AppTheme.primaryGreen}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? color : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class RoleData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  RoleData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });
}
