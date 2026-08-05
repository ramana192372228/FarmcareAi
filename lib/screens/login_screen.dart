import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/auth_service.dart';
import 'registration_form_screen.dart';
import 'farmer_dashboard.dart';
import 'shop/shop_dashboard.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'farmer' or 'shop'
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final auth = AuthService();

    try {
      final user = await auth.signInWithGoogle();
      if (user == null) {
        // Sign-in cancelled
        setState(() => _isLoading = false);
        return;
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('Google account does not provide an email.');
      }

      // Look up Firestore profile by email and role
      final profile = await auth.getUserProfileByEmailAndRole(email, widget.role);

      if (profile != null) {
        // Returning User with selected role! Setup session cache and redirect
        await auth.login(profile.userId, widget.role);

        if (mounted) {
          Widget dashboard;
          if (widget.role == 'farmer') {
            dashboard = const FarmerDashboard();
          } else if (widget.role == 'shop') {
            dashboard = const ShopDashboard();
          } else {
            dashboard = const AdminDashboard();
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => dashboard),
            (route) => false,
          );
        }
      } else {
        // First Login for this role! Direct to Registration Form
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegistrationFormScreen(
                role: widget.role,
                phone: '',
                email: email,
                initialName: user.displayName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Google Sign-In failed: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();
    String roleTitle = trans.translate('role_farmer_title');
    Color themeColor = AppTheme.primaryGreen;
    IconData roleIcon = Icons.agriculture_rounded;

    if (widget.role == 'shop') {
      roleTitle = trans.translate('role_shop_title');
      themeColor = AppTheme.accentGold;
      roleIcon = Icons.storefront_rounded;
    } else if (widget.role == 'admin') {
      roleTitle = 'Administrator';
      themeColor = Colors.indigo;
      roleIcon = Icons.admin_panel_settings_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: themeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.role != 'admin')
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                );
              },
              icon: Icon(Icons.admin_panel_settings_rounded, size: 18, color: themeColor),
              label: Text('Admin', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withValues(alpha: 0.02),
              AppTheme.backgroundLight,
              themeColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        roleIcon,
                        size: 64,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Welcome Title
                    Text(
                      'Sign In as $roleTitle',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: widget.role == 'farmer' ? AppTheme.primaryGreen : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Authenticate securely with your Google account to access your personalized farming dashboard.',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Google Sign-In Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.05),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: themeColor)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://developers.google.com/static/identity/images/g-logo.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'CONTINUE WITH GOOGLE',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Secondary Admin Login link for clear navigation
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                        );
                      },
                      icon: Icon(Icons.security_rounded, size: 16, color: Colors.grey[600]),
                      label: Text(
                        'Access Administrator Portal',
                        style: TextStyle(
                          color: Colors.grey[650],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
