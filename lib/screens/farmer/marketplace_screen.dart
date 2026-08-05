import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _cartItems = [];
  int _cartCount = 0;
  double _totalCartPrice = 0.0;
  
  String _userId = 'FAR1234';
  String _userName = 'Rajesh Kumar';

  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();

  final Map<AppLanguage, Map<String, String>> _localizedMarket = {
    AppLanguage.english: {
      'buy': 'Buy Inputs',
      'sell': 'Sell Crop Harvest',
      'seeds': 'Premium Seeds',
      'fertilizer': 'Certified Fertilizer',
      'tools': 'Farming Tools',
      'cart': 'Cart',
      'add_to_cart': 'Add to Cart',
      'total': 'Total',
      'sell_header': 'Submit Procurement Offer',
      'crop_label': 'Crop Name',
      'weight_label': 'Harvest Weight (kg)',
      'price_label': 'Target Price (per kg)',
      'submit_btn': 'Post Sale Offer',
      'success_msg': 'Crop offer successfully published to Shop Owners!',
      'my_offers': 'Your Listed Offers',
      'no_offers': 'No harvest listings posted yet.',
      'validation_empty': 'Field cannot be empty',
    },
    AppLanguage.telugu: {
      'buy': 'విత్తనాలు & ఎరువులు',
      'sell': 'దిగుబడి అమ్మకాలు',
      'seeds': 'నాణ్యమైన విత్తనాలు',
      'fertilizer': 'ధృవీకరించబడిన ఎరువులు',
      'tools': 'వ్యవసాయ పరికరాలు',
      'cart': 'కార్ట్',
      'add_to_cart': 'కార్ట్‌కు జోడించు',
      'total': 'మొತ್ತం',
      'sell_header': 'పంట విక్రయ ప్రతిపాదన',
      'crop_label': 'పంట పేరు',
      'weight_label': 'దిగుబడి బరువు (కేజీలు)',
      'price_label': 'ఆశించిన ధర (కేజీకి)',
      'submit_btn': 'విక్రయానికి ఉంచు',
      'success_msg': 'పంట విక్రయ ప్రతిపాదన దుకాణదారులకు విజయవంతంగా పంపబడింది!',
      'my_offers': 'మీరు ఉంచిన ప్రతిపాదనలు',
      'no_offers': 'ఇంಕಾ ఎలాంటి ప్రతిపాదనలు పెట్టలేదు.',
      'validation_empty': 'విలువను నమోదు చేయండి',
    },
    AppLanguage.tamil: {
      'buy': 'உள்ளீடுகள் கொள்முதல்',
      'sell': 'அறுவடை விற்பனை',
      'seeds': 'தரமான விதைகள்',
      'fertilizer': 'சான்றளிக்கப்பட்ட உரம்',
      'tools': 'விவசாயக் கருவிகள்',
      'cart': 'கூடை',
      'add_to_cart': 'கூடையில் சேர்',
      'total': 'மொத்தம்',
      'sell_header': 'கொள்முதல் சலுகையை சமர்ப்பி',
      'crop_label': 'பயிர் பெயர்',
      'weight_label': 'அறுவடை எடை (கிலோ)',
      'price_label': 'இலக்கு விலை (கிலோவுக்கு)',
      'submit_btn': 'விற்பனை சலுகையை வெளியிடு',
      'success_msg': 'பயிர் சലுகை வெற்றிகரமாக கடை உரிமையாளர்களுக்கு அனுப்பப்பட்டது!',
      'my_offers': 'உங்கள் விற்பனை சலுகைகள்',
      'no_offers': 'விற்பனை சலுகைகள் எதுவும் இதுவரை வெளியிடப்படவில்லை.',
      'validation_empty': 'இந்த புலத்தை நிரப்பவும்',
    },
    AppLanguage.hindi: {
      'buy': 'कृषि सामग्री खरीदें',
      'sell': 'फसल उपज बेचें',
      'seeds': 'प्रमाणित बीज',
      'fertilizer': 'प्रमाणित खाद',
      'tools': 'कृषि उपकरण',
      'cart': 'कार्ट',
      'add_to_cart': 'कार्ट में जोड़ें',
      'total': 'कुल',
      'sell_header': 'फसल खरीद प्रस्ताव जमा करें',
      'crop_label': 'फसल का नाम',
      'weight_label': 'कुल वजन (किग्रा)',
      'price_label': 'लक्षित मूल्य (प्रति किग्रा)',
      'submit_btn': 'बिक्री प्रस्ताव पोस्ट करें',
      'success_msg': 'फसल का प्रस्ताव सफलतापूर्वक दुकानदारों को भेज दिया गया है!',
      'my_offers': 'आपके द्वारा सूचीबद्ध प्रस्ताव',
      'no_offers': 'अभी तक कोई प्रस्ताव पोस्ट नहीं किया गया है।',
      'validation_empty': 'यह फ़ील्ड खाली नहीं हो सकती',
    },
    AppLanguage.kannada: {
      'buy': 'ಪರಿಕರಗಳ ಖರೀದಿ',
      'sell': 'ಬೆಳೆ ಇಳುವರಿ ಮಾರಾಟ',
      'seeds': 'ಉತ್ತಮ ಬೀಜಗಳು',
      'fertilizer': 'ಪ್ರಮಾಣೀಕೃತ ಗೊಬ್ಬರ',
      'tools': 'ಕೃಷಿ ಉಪಕರಣಗಳು',
      'cart': 'ಕಾರ್ಟ್',
      'add_to_cart': 'ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಿ',
      'total': 'ಒಟ್ಟು',
      'sell_header': 'ಬೆಳೆ ಮಾರಾಟದ ಪ್ರಸ್ತಾಪ',
      'crop_label': 'ಬೆಳೆಯ ಹೆಸರು',
      'weight_label': 'ಬೆಳೆಯ ತೂಕ (ಕೆಜಿ)',
      'price_label': 'ನಿರೀಕ್ಷಿತ ಬೆಲೆ (ಕೆಜಿಗೆ)',
      'submit_btn': 'ಮಾರಾಟ ಪ್ರಸ್ತಾಪ ಸಲ್ಲಿಸಿ',
      'success_msg': 'ಬೆಳೆ ಮಾರಾಟದ ಪ್ರಸ್ತಾಪವನ್ನು ಅಂಗಡಿಯವರಿಗೆ ಯಶಸ್ವಿಯಾಗಿ ಕಳುಹಿಸಲಾಗಿದೆ!',
      'my_offers': 'ನಿಮ್ಮ ಮಾರಾಟ ಪ್ರಸ್ತಾಪಗಳು',
      'no_offers': 'ಯಾವುದೇ ಮಾರಾಟ ಪ್ರಸ್ತಾಪಗಳನ್ನು ಸಲ್ಲಿಸಿಲ್ಲ.',
      'validation_empty': 'ದಯವಿಟ್ಟು ನಮೂದಿಸಿ',
    },
    AppLanguage.malayalam: {
      'buy': 'കാർഷിക സാമഗ്രികൾ',
      'sell': 'വിളവെടുപ്പ് വിൽക്കുക',
      'seeds': 'ഗുണമേന്മയുള്ള വിത്തുകൾ',
      'fertilizer': 'സാക്ഷ്യപ്പെടുത്തിയ വളം',
      'tools': 'കാർഷിക ഉപകരണങ്ങൾ',
      'cart': 'കൂട്ടത്തിൽ',
      'add_to_cart': 'കൂട്ടത്തിൽ ചേർക്കുക',
      'total': 'ആകെ',
      'sell_header': 'വിള സംഭരണ ഓഫർ',
      'crop_label': 'വിളയുടെ പേര്',
      'weight_label': 'വിളവെടുത്ത ഭാരം (കിലോഗ്രാം)',
      'price_label': 'ആവശ്യപ്പെടുന്ന വില (കിലോയ്ക്ക്)',
      'submit_btn': 'വിൽപ്പന ഓഫർ പോസ്റ്റ് ചെയ്യുക',
      'success_msg': 'വിള ഓഫർ വിജയകരമായി വ്യാപാരികൾക്ക് ലഭ്യമാക്കിയിട്ടുണ്ട്!',
      'my_offers': 'നിങ്ങൾ പോസ്റ്റ് ചെയ്ത ഓഫറുകൾ',
      'no_offers': 'വിൽപന ഓഫറുകൾ ഒന്നും ഇതുവരെ ലഭ്യമാക്കിയിട്ടില്ല.',
      'validation_empty': 'ഈ ഫീൽഡ് പൂരിപ്പിക്കുക',
    },
  };

  String _getText(String key) {
    final lang = TranslationService().currentLanguage;
    final map = _localizedMarket[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return _localizedMarket[AppLanguage.english]![key]!;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUserAndCart();
  }

  Future<void> _initializeUserAndCart() async {
    final auth = AuthService();
    final phone = await auth.getLoggedUserPhone();
    if (phone != null && phone.isNotEmpty) {
      _userId = phone;
      final profile = await auth.getUserProfile(phone);
      if (profile != null) {
        _userName = profile.name;
      }
    }

    // Load cart from SharedPreferences cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final localCart = prefs.getString('local_cart_$_userId');
      if (localCart != null) {
        final decoded = jsonDecode(localCart) as List;
        if (mounted) {
          setState(() {
            _cartItems.clear();
            _cartItems.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
            _updateCartCountAndTotal();
          });
        }
      }
    } catch (e) {
      debugPrint('[MARKETPLACE] Error loading cached cart: $e');
    }

    // Subscribe to live cart updates in Firestore
    FirestoreService().getCartStream(_userId).listen((cartData) {
      if (cartData != null && cartData.containsKey('items')) {
        final List items = cartData['items'];
        if (mounted) {
          setState(() {
            _cartItems.clear();
            _cartItems.addAll(items.map((e) => Map<String, dynamic>.from(e)));
            _updateCartCountAndTotal();
          });
          // Cache locally
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('local_cart_$_userId', jsonEncode(_cartItems));
          });
        }
      }
    }, onError: (err) {
      debugPrint('[MARKETPLACE] Firestore cart stream error: $err');
    });
  }

  void _updateCartCountAndTotal() {
    int count = 0;
    double price = 0.0;
    for (var item in _cartItems) {
      final int qty = item['quantity'] ?? 0;
      final double pr = (item['price'] ?? 0.0).toDouble();
      count += qty;
      price += (qty * pr);
    }
    _cartCount = count;
    _totalCartPrice = price;
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final productId = product['id'] as String;
    final price = (product['price'] as num).toDouble();
    final name = product['name'] as String;

    int existingIndex = _cartItems.indexWhere((item) => item['productId'] == productId);

    setState(() {
      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity']++;
      } else {
        _cartItems.add({
          'productId': productId,
          'productName': name,
          'quantity': 1,
          'price': price,
        });
      }
      _updateCartCountAndTotal();
    });

    try {
      await FirestoreService().saveCart(_userId, _cartItems);
      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_cart_$_userId', jsonEncode(_cartItems));
    } catch (e) {
      debugPrint('[MARKETPLACE] Failed to save cart to Firestore: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('Item added to cart! Total: ₹${_totalCartPrice.toStringAsFixed(2)}'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkoutCart() async {
    if (_cartItems.isEmpty) return;

    try {
      // Determine shopId from items (or fall back to placeholder SHOP1234)
      final String shopId = _cartItems[0]['shopId'] ?? 'SHOP1234';

      final orderData = {
        'farmerId': _userId,
        'farmerName': _userName,
        'shopId': shopId,
        'items': _cartItems,
        'totalAmount': _totalCartPrice,
        'status': 'PENDING',
      };

      await FirestoreService().placeOrder(orderData);
      await FirestoreService().clearCart(_userId);

      setState(() {
        _cartItems.clear();
        _updateCartCountAndTotal();
      });

      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_cart_$_userId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order successfully placed with the Shop Owner!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitHarvestOffer() async {
    if (_formKey.currentState!.validate()) {
      final crop = _cropController.text.trim();
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      try {
        final offerData = {
          'farmerId': _userId,
          'farmerName': _userName,
          'crop': crop,
          'weight': weight,
          'pricePerKg': price,
          'status': 'PENDING',
          'acceptedBy': null,
        };

        await FirestoreService().postCropOffer(offerData);

        _cropController.clear();
        _weightController.clear();
        _priceController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getText('success_msg')),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to publish crop offer: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cropController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();
    final firestore = FirestoreService();

    // Static fallback items if Firestore has no products registered
    final List<Map<String, dynamic>> localSeeds = [
      {'id': 'seed_1', 'name': 'Hybrid Cotton Seeds H-4', 'price': 350.00, 'unit': '450g Pack', 'category': 'SEEDS'},
      {'id': 'seed_2', 'name': 'Basmati Rice Seeds Super-1', 'price': 890.00, 'unit': '5kg Bag', 'category': 'SEEDS'},
      {'id': 'seed_3', 'name': 'Desi Tomato Seeds High Yield', 'price': 180.00, 'unit': '100g Pouch', 'category': 'SEEDS'},
    ];

    final List<Map<String, dynamic>> localFertilizer = [
      {'id': 'fert_1', 'name': 'Organic Neem Cake Cake-Powder', 'price': 420.00, 'unit': '10kg Bag', 'category': 'FERTILIZER'},
      {'id': 'fert_2', 'name': 'Water Soluble NPK (19:19:19)', 'price': 150.00, 'unit': '1kg pack', 'category': 'FERTILIZER'},
      {'id': 'fert_3', 'name': 'Bio-Potash Booster Nutrient', 'price': 280.00, 'unit': '1L Bottle', 'category': 'FERTILIZER'},
    ];

    final List<Map<String, dynamic>> localTools = [
      {'id': 'tool_1', 'name': 'Ergonomic Heavy Hand Weeder', 'price': 450.00, 'unit': '1 unit', 'category': 'EQUIPMENT'},
      {'id': 'tool_2', 'name': 'Agricultural Heavy Garden Spade', 'price': 650.00, 'unit': '1 unit', 'category': 'EQUIPMENT'},
      {'id': 'tool_3', 'name': '16L Manual Knapsack Sprayer', 'price': 1200.00, 'unit': '1 unit', 'category': 'EQUIPMENT'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(trans.translate('marketplace')),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text(_getText('cart')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Items: $_cartCount'),
                          const SizedBox(height: 8),
                          Text('Cart Total Value: ₹${_totalCartPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        if (_cartCount > 0)
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _checkoutCart();
                            },
                            child: const Text('Checkout', style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentGold,
          indicatorWeight: 3.5,
          tabs: [
            Tab(text: _getText('buy')),
            Tab(text: _getText('sell')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // BUY MODULE TAB PANEL
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestore.getProductsStream(null),
            builder: (context, snapshot) {
              List<Map<String, dynamic>> seeds = localSeeds;
              List<Map<String, dynamic>> fertilizer = localFertilizer;
              List<Map<String, dynamic>> tools = localTools;

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final allProds = snapshot.data!;
                final sList = allProds.where((p) => p['category'] == 'SEEDS').toList();
                final fList = allProds.where((p) => p['category'] == 'FERTILIZER').toList();
                final tList = allProds.where((p) => p['category'] == 'EQUIPMENT').toList();

                if (sList.isNotEmpty) seeds = sList;
                if (fList.isNotEmpty) fertilizer = fList;
                if (tList.isNotEmpty) tools = tList;
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Seeds Catalog
                      _buildCatalogHeader(_getText('seeds')),
                      const SizedBox(height: 12),
                      _buildProductsList(seeds),
                      const SizedBox(height: 28),

                      // 2. Fertilizer Catalog
                      _buildCatalogHeader(_getText('fertilizer')),
                      const SizedBox(height: 12),
                      _buildProductsList(fertilizer),
                      const SizedBox(height: 28),

                      // 3. Equipment/Tools Catalog
                      _buildCatalogHeader(_getText('tools')),
                      const SizedBox(height: 12),
                      _buildProductsList(tools),
                    ],
                  ),
                ),
              );
            }
          ),

          // SELL MODULE TAB PANEL
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getText('sell_header'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cropController,
                      decoration: InputDecoration(
                        labelText: _getText('crop_label'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('validation_empty') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _getText('weight_label'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('validation_empty') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _getText('price_label'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? _getText('validation_empty') : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitHarvestOffer,
                        child: Text(_getText('submit_btn'), style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Active Listed Bids from Firestore
                    Text(
                      _getText('my_offers'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: firestore.getFarmerCropOffersStream(_userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                            ),
                            child: Center(
                              child: Text(
                                _getText('no_offers'),
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        }

                        final offers = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            final status = offer['status'] as String? ?? 'PENDING';
                            Color statusColor = Colors.orange;
                            if (status == 'ACCEPTED') statusColor = Colors.green;
                            if (status == 'REJECTED') statusColor = Colors.red;

                            return Card(
                              color: Colors.white,
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.agriculture_rounded, color: AppTheme.primaryGreen),
                                ),
                                title: Text(offer['crop'] ?? 'Crop', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Weight: ${offer['weight']} kg • Target: ₹${offer['pricePerKg']}/kg'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
    );
  }

  Widget _buildProductsList(List<Map<String, dynamic>> products) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final prod = products[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGreen, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prod['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Unit: ${prod['unit']}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      const SizedBox(height: 4),
                      Text('₹${prod['price']}', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _addToCart(prod),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  child: Text(_getText('add_to_cart'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
