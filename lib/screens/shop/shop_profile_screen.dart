import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String _userId = '';

  // Controllers
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _workingHoursCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final auth = AuthService();
    final phone = await auth.getLoggedUserPhone();
    _userId = phone ?? 'SHOP1234';

    final profile = await auth.getUserProfile(_userId);
    final firestoreProfile = await FirestoreService().getUserProfile(_userId);

    _shopNameCtrl.text = firestoreProfile?['shopName'] ?? profile?.shopName ?? 'Sri Rama Traders';
    _ownerNameCtrl.text = firestoreProfile?['name'] ?? profile?.name ?? 'Sreenivas Rao';
    _licenseCtrl.text = firestoreProfile?['licenseNumber'] ?? 'AP-GNT-AGRI-2024-8891';
    _gstCtrl.text = firestoreProfile?['gstNumber'] ?? '37AAAAA0000A1Z5';
    _phoneCtrl.text = firestoreProfile?['phone'] ?? profile?.phone ?? _userId;
    _emailCtrl.text = firestoreProfile?['email'] ?? profile?.email ?? 'shop@sriramaproducts.com';
    _addressCtrl.text = firestoreProfile?['address'] ?? profile?.address ?? 'Shop No. 12, Main Market Road';
    _districtCtrl.text = firestoreProfile?['district'] ?? profile?.district ?? 'Guntur';
    _stateCtrl.text = firestoreProfile?['state'] ?? 'Andhra Pradesh';
    _workingHoursCtrl.text = firestoreProfile?['workingHours'] ?? '8:00 AM - 8:00 PM (Mon - Sat)';
    _descCtrl.text = firestoreProfile?['description'] ?? 'Authorized dealer for high-yield hybrid seeds, bio-fertilizers, and farm machinery rentals.';

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirestoreService().saveUserProfile(
        userId: _userId,
        name: _ownerNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: 'shop',
        email: _emailCtrl.text.trim(),
        shopName: _shopNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile successfully updated!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Business Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            onPressed: _isSaving ? null : _saveProfile,
            tooltip: 'Save Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                  child: const Icon(Icons.storefront_rounded, size: 48, color: AppTheme.primaryGreen),
                                ),
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppTheme.accentGold,
                                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(_shopNameCtrl.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('ID: $_userId • Registered Agri-Distributor', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Business Identity Section
                      _buildSectionHeader('Business Identity', Icons.verified_user_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_shopNameCtrl, 'Shop / Firm Name', Icons.store_rounded, validator: (val) => val == null || val.isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      _buildTextField(_ownerNameCtrl, 'Owner / Manager Name', Icons.person_rounded, validator: (val) => val == null || val.isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_licenseCtrl, 'License No.', Icons.badge_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_gstCtrl, 'GST Number (Optional)', Icons.receipt_long_rounded)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Contact & Location Section
                      _buildSectionHeader('Contact & Location', Icons.location_on_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_phoneCtrl, 'Phone Number', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_emailCtrl, 'Email Address', Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(_addressCtrl, 'Shop Address', Icons.home_work_rounded, maxLines: 2),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_districtCtrl, 'District', Icons.map_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_stateCtrl, 'State', Icons.public_rounded)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Operating Details Section
                      _buildSectionHeader('Operating Info', Icons.access_time_filled_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(_workingHoursCtrl, 'Working Hours', Icons.schedule_rounded),
                      const SizedBox(height: 14),
                      _buildTextField(_descCtrl, 'Shop Description & Specialties', Icons.description_rounded, maxLines: 3),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: const Icon(Icons.save_rounded, color: Colors.white),
                          label: Text(_isSaving ? 'SAVING...' : 'SAVE BUSINESS PROFILE', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
      ),
    );
  }
}
