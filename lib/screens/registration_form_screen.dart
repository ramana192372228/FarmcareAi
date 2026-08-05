import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import '../services/auth_service.dart';
import 'farmer_dashboard.dart';
import 'shop/shop_dashboard.dart';
import 'admin/admin_dashboard.dart';

class RegistrationFormScreen extends StatefulWidget {
  final String role; // 'farmer', 'shop', or 'admin'
  final String phone;
  final String? email;
  final String? initialName;
  const RegistrationFormScreen({
    super.key,
    required this.role,
    required this.phone,
    this.email,
    this.initialName,
  });

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Farmer controllers
  final _farmerNameController = TextEditingController();
  final _farmerVillageController = TextEditingController();
  final _farmerDistrictController = TextEditingController();

  // Shop controllers
  final _shopNameController = TextEditingController();
  final _shopOwnerNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  // Common Phone controller for Google flow
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _farmerNameController.text = widget.initialName!;
      _shopOwnerNameController.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _farmerVillageController.dispose();
    _farmerDistrictController.dispose();
    _shopNameController.dispose();
    _shopOwnerNameController.dispose();
    _shopAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = AuthService();

    try {
      String generatedId = '';
      final phone = widget.phone.isNotEmpty ? widget.phone : _phoneController.text.trim();

      if (widget.role == 'farmer') {
        generatedId = await auth.registerFarmer(
          name: _farmerNameController.text.trim(),
          phone: phone,
          email: widget.email,
          village: _farmerVillageController.text.trim(),
          district: _farmerDistrictController.text.trim(),
        );
      } else if (widget.role == 'shop') {
        generatedId = await auth.registerShop(
          shopName: _shopNameController.text.trim(),
          ownerName: _shopOwnerNameController.text.trim(),
          phone: phone,
          email: widget.email,
          address: _shopAddressController.text.trim(),
        );
      } else {
        generatedId = await auth.registerAdmin(
          name: _farmerNameController.text.trim().isNotEmpty ? _farmerNameController.text.trim() : 'Administrator',
          phone: phone,
          email: widget.email ?? 'admin@farmcare.ai',
        );
      }

      setState(() => _isLoading = false);
      _showRegistrationSuccessDialog(generatedId);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showRegistrationSuccessDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isFarmer = widget.role == 'farmer';
        final themeColor = isFarmer ? AppTheme.primaryGreen : AppTheme.accentGold;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: themeColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Registration Successful!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your dynamic FarmCare AI User ID is generated. Please copy it for your records:',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userId,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: themeColor),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: userId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User ID copied to clipboard!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop(); // Dismiss Dialog
                
                // Login session setup
                await AuthService().login(userId, widget.role);

                Widget dashboard;
                if (widget.role == 'farmer') {
                  dashboard = const FarmerDashboard();
                } else if (widget.role == 'shop') {
                  dashboard = const ShopDashboard();
                } else {
                  dashboard = const AdminDashboard();
                }
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => dashboard),
                  (route) => false,
                );
              },
              child: Text(
                'PROCEED TO DASHBOARD',
                style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();
    final isFarmer = widget.role == 'farmer';
    final themeColor = isFarmer ? AppTheme.primaryGreen : AppTheme.accentGold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 2,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to FarmCare AI!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.phone.isNotEmpty
                          ? 'Provide your details to complete your registration for phone number +91 ${widget.phone}.'
                          : 'Provide your details to complete your registration for email ${widget.email}.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                    ),
                    const SizedBox(height: 32),

                    if (isFarmer) ...[
                      // Farmer Profile Fields
                      Text(
                        trans.translate('name_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _farmerNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: themeColor, width: 2.0)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 24),

                      if (widget.phone.isEmpty) _buildPhoneField(themeColor),

                      Text(
                        trans.translate('village_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _farmerVillageController,
                        decoration: InputDecoration(
                          hintText: 'Enter your village name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: themeColor, width: 2.0)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Village name is required' : null,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        trans.translate('district_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _farmerDistrictController,
                        decoration: InputDecoration(
                          hintText: 'Enter your district name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: themeColor, width: 2.0)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'District name is required' : null,
                      ),
                    ] else ...[
                      // Shop Owner Profile Fields
                      Text(
                        trans.translate('shop_name_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter shop business name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: themeColor, width: 2.0)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Shop name is required' : null,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        trans.translate('owner_name_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _shopOwnerNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter owner full name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: themeColor, width: 2.0)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Owner name is required' : null,
                      ),
                      const SizedBox(height: 24),

                      if (widget.phone.isEmpty) _buildPhoneField(themeColor),

                      Text(
                        trans.translate('address_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _shopAddressController,
                        decoration: InputDecoration(
                          hintText: 'Enter shop full street address',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: themeColor, width: 2.0)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Address is required' : null,
                      ),
                    ],
                    
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: themeColor.withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'COMPLETE REGISTRATION',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: '+91 ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            hintText: 'Enter 10-digit number',
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: themeColor, width: 2.0)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            if (value.trim().length != 10) {
              return 'Please enter a valid 10-digit phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
