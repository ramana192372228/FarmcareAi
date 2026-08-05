import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class UserProfile {
  final String userId;
  final String role;
  final String password;
  final String phone;
  final String name; // Farmer: Name, Shop Owner: Owner Name
  final String? email;
  final String? village; // Farmer only
  final String? district; // Farmer only
  final String? shopName; // Shop Owner only
  final String? address; // Shop Owner only

  UserProfile({
    required this.userId,
    required this.role,
    required this.password,
    required this.phone,
    required this.name,
    this.email,
    this.village,
    this.district,
    this.shopName,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'role': role,
    'password': password,
    'phone': phone,
    'name': name,
    'email': email,
    'village': village,
    'district': district,
    'shopName': shopName,
    'address': address,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'] as String? ?? '',
    role: json['role'] as String? ?? 'farmer',
    password: json['password'] as String? ?? 'password',
    phone: json['phone'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    village: json['village'] as String?,
    district: json['district'] as String?,
    shopName: json['shopName'] as String?,
    address: json['address'] as String?,
  );
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '788933995877-web-placeholder.apps.googleusercontent.com' : null,
  );
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Local persistent database of users: userId -> UserProfile
  final Map<String, UserProfile> _userRegistry = {};

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    // Pre-seed standard accounts
    _seedDefaultAccounts();

    // Load registered users from SharedPreferences
    final savedRegistryJson = _prefs!.getString('user_registry_json');
    if (savedRegistryJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedRegistryJson);
        decoded.forEach((key, value) {
          _userRegistry[key] = UserProfile.fromJson(value as Map<String, dynamic>);
        });
      } catch (e) {
        debugPrint('[AUTH_SERVICE] Exception loading user registry: $e');
      }
    }
    debugPrint('[AUTH_SERVICE] Initialized user registry: ${_userRegistry.keys.toList()}');
  }

  void _seedDefaultAccounts() {
    // Seed Farmer Rajesh Kumar
    _userRegistry['FAR1234'] = UserProfile(
      userId: 'FAR1234',
      role: 'farmer',
      password: 'password',
      phone: '9876543210',
      name: 'Rajesh Kumar',
      village: 'Ramapuram',
      district: 'Guntur',
    );

    // Seed Shop Owner Sreenivas Rao
    _userRegistry['SHOP1234'] = UserProfile(
      userId: 'SHOP1234',
      role: 'shop',
      password: 'password',
      phone: '8765432109',
      name: 'Sreenivas Rao',
      shopName: 'Sri Rama Traders',
      address: 'Shop No. 12, Market Road, Guntur',
    );
  }

  // Generate unique User ID: FARxxxx or SHOPxxxx
  String generateUniqueUserId(String role) {
    final prefix = role.toLowerCase() == 'farmer' ? 'FAR' : 'SHOP';
    final random = Random();
    String generatedId;
    do {
      final code = random.nextInt(9000) + 1000;
      generatedId = '$prefix$code';
    } while (_userRegistry.containsKey(generatedId));
    return generatedId;
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;

  // Register a new Farmer profile
  Future<String> registerFarmer({
    required String name,
    required String phone,
    String? email,
    String password = 'password',
    required String village,
    required String district,
  }) async {
    await init();
    final userId = currentUser?.uid ?? generateUniqueUserId('farmer');
    final profile = UserProfile(
      userId: userId,
      role: 'farmer',
      password: password,
      phone: phone,
      name: name,
      email: email,
      village: village,
      district: district,
    );

    _userRegistry[userId] = profile;
    await _saveRegistry();
    debugPrint('[AUTH_SERVICE] Registered Farmer $name with ID: $userId');

    // Save user profile to Firestore using Firebase Auth UID if logged in
    await FirestoreService().saveUserProfile(
      userId: userId,
      name: name,
      phone: phone,
      role: 'farmer',
      email: email,
      village: village,
      district: district,
    );

    return userId;
  }

  // Register a new Shop Owner profile
  Future<String> registerShop({
    required String shopName,
    required String ownerName,
    required String phone,
    String? email,
    String password = 'password',
    required String address,
  }) async {
    await init();
    final userId = currentUser?.uid ?? generateUniqueUserId('shop');
    final profile = UserProfile(
      userId: userId,
      role: 'shop',
      password: password,
      phone: phone,
      name: ownerName,
      email: email,
      shopName: shopName,
      address: address,
    );

    _userRegistry[userId] = profile;
    await _saveRegistry();
    debugPrint('[AUTH_SERVICE] Registered Shop Owner $ownerName with ID: $userId');

    // Save user profile to Firestore using Firebase Auth UID if logged in
    await FirestoreService().saveUserProfile(
      userId: userId,
      name: ownerName,
      phone: phone,
      role: 'shop',
      email: email,
      shopName: shopName,
      address: address,
    );

    return userId;
  }

  // Check if a Phone is already registered
  Future<bool> isPhoneRegistered(String phone) async {
    await init();
    final localExists = _userRegistry.values.any((p) => p.phone == phone);
    if (localExists) return true;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Error checking phone in Firestore: $e');
    }
    return false;
  }

  // Check if User ID exists
  Future<bool> isUserIdRegistered(String userId) async {
    await init();
    return _userRegistry.containsKey(userId.toUpperCase().trim());
  }

  // Get user profile details by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    await init();
    final localProfile = _userRegistry[userId.toUpperCase().trim()];
    if (localProfile != null) return localProfile;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId.toUpperCase().trim()).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['userId'] = doc.id;
        final profile = UserProfile.fromJson(data);
        _userRegistry[profile.userId] = profile;
        await _saveRegistry();
        return profile;
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Error fetching profile by ID from Firestore: $e');
    }
    return null;
  }

  // Get user profile details by Phone Number
  Future<UserProfile?> getUserProfileByPhone(String phone) async {
    await init();
    for (final profile in _userRegistry.values) {
      if (profile.phone == phone) {
        return profile;
      }
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        data['userId'] = doc.id;
        final profile = UserProfile.fromJson(data);
        _userRegistry[profile.userId] = profile;
        await _saveRegistry();
        return profile;
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Error fetching user profile by phone: $e');
    }
    return null;
  }

  // Get user profile details by Email
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    await init();
    for (final profile in _userRegistry.values) {
      if (profile.email == email) {
        return profile;
      }
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        data['userId'] = doc.id;
        final profile = UserProfile.fromJson(data);
        _userRegistry[profile.userId] = profile;
        await _saveRegistry();
        return profile;
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Error fetching user profile by email: $e');
    }
    return null;
  }

  // Sign in using Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb && _auth != null) {
        try {
          final GoogleAuthProvider googleProvider = GoogleAuthProvider();
          final UserCredential userCredential = await _auth!.signInWithPopup(googleProvider);
          return userCredential.user;
        } catch (e) {
          debugPrint('[AUTH_SERVICE] Web Google popup sign-in attempt failed, falling back: $e');
        }
      }

      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // 2. Obtain authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential for Firebase Authentication
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      if (_auth == null) return null;
      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Error during Google Sign-In: $e');
      rethrow;
    }
  }

  // Session Caching Helper
  Future<void> _cacheSession(String userId, String role) async {
    await init();
    await _prefs!.setBool('is_logged_in', true);
    await _prefs!.setString('logged_user_phone', userId);
    await _prefs!.setString('logged_user_role', role);
  }

  // Set active user session
  Future<void> login(String userId, String role) async {
    await _cacheSession(userId, role);
    debugPrint('[AUTH_SERVICE] Session logged in: $userId ($role)');

    // Ensure profile is synced to Firestore
    final profile = await getUserProfile(userId);
    if (profile != null) {
      await FirestoreService().saveUserProfile(
        userId: profile.userId,
        name: profile.name,
        phone: profile.phone,
        role: profile.role,
        village: profile.village,
        district: profile.district,
        shopName: profile.shopName,
        address: profile.address,
      );

      // Record in login_history and audit_logs
      await FirestoreService().saveLoginRecord(
        uid: profile.userId,
        name: profile.name,
        email: profile.email,
        role: profile.role,
      );
      await FirestoreService().logAuditEvent(
        userId: profile.userId,
        userName: profile.name,
        action: 'User Login',
        category: 'AUTHENTICATION',
        details: 'Role: ${profile.role}',
      );
    }
    notifyListeners();
  }

  // Set admin session with Firebase Email/Password Auth
  Future<void> loginAdmin({required String email, required String password}) async {
    await init();
    
    // Sign in using Firebase Email/Password Auth
    if (_auth != null) {
      try {
        final UserCredential credential = await _auth!.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('[AUTH_SERVICE] Admin successfully logged in to Firebase: ${credential.user?.email}');
      } catch (e) {
        debugPrint('[AUTH_SERVICE] Admin Firebase login error: $e');
      }
    }
    
    final userId = currentUser?.uid ?? 'admin';
    await _cacheSession(userId, 'admin');

    await FirestoreService().saveLoginRecord(
      uid: userId,
      name: 'Administrator',
      email: email,
      role: 'admin',
    );
    await FirestoreService().logAuditEvent(
      userId: userId,
      userName: 'Administrator',
      action: 'Admin Login',
      category: 'AUTHENTICATION',
      details: 'Email: $email',
    );

    notifyListeners();
  }

  // Register a new Admin profile
  Future<String> registerAdmin({
    required String name,
    required String phone,
    required String email,
    String password = 'password',
  }) async {
    await init();
    final userId = currentUser?.uid ?? generateUniqueUserId('admin');
    final profile = UserProfile(
      userId: userId,
      role: 'admin',
      password: password,
      phone: phone,
      name: name,
      email: email,
    );

    _userRegistry[userId] = profile;
    await _saveRegistry();
    debugPrint('[AUTH_SERVICE] Registered Admin $name with ID: $userId');

    await FirestoreService().saveUserProfile(
      userId: userId,
      name: name,
      phone: phone,
      role: 'admin',
      email: email,
    );

    return userId;
  }

  // Get user profile by Email AND Role
  Future<UserProfile?> getUserProfileByEmailAndRole(String email, String role) async {
    await init();
    for (final profile in _userRegistry.values) {
      if (profile.email == email && profile.role == role) {
        return profile;
      }
    }

    try {
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
        if (doc.exists && doc.data()?['role'] == role) {
          final data = doc.data()!;
          data['userId'] = doc.id;
          final profile = UserProfile.fromJson(data);
          _userRegistry[profile.userId] = profile;
          await _saveRegistry();
          return profile;
        }
      }

      final snapshot = await FirebaseFirestore.instance.collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: role)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        data['userId'] = doc.id;
        final profile = UserProfile.fromJson(data);
        _userRegistry[profile.userId] = profile;
        await _saveRegistry();
        return profile;
      }
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Error fetching user profile by email and role: $e');
    }
    return null;
  }

  // Sign out from Google Sign-In to allow selecting another Google account
  Future<void> switchGoogleAccount() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      debugPrint('[AUTH_SERVICE] Disconnected Google Sign-In session.');
    } catch (e) {
      debugPrint('[AUTH_SERVICE] Error disconnecting Google Sign-In session: $e');
    }
    await logout();
  }

  // Clear session on logout
  Future<void> logout() async {
    await init();
    final uid = await getLoggedUserPhone();
    if (uid != null) {
      await FirestoreService().updateLogoutRecord(uid);
      await FirestoreService().logAuditEvent(
        userId: uid,
        action: 'User Logout',
        category: 'AUTHENTICATION',
      );
    }

    if (_prefs != null) {
      await _prefs!.setBool('is_logged_in', false);
      await _prefs!.remove('logged_user_phone');
      await _prefs!.remove('logged_user_role');
    }
    
    // Sign out from Firebase Auth & Google
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth?.signOut();
    } catch (_) {}
    debugPrint('[AUTH_SERVICE] Logged out from Firebase Auth & SharedPreferences.');
    notifyListeners();
  }

  // Session Checker using Firebase Auth as source of truth
  Future<bool> isLoggedIn() async {
    await init();
    final role = _prefs?.getString('logged_user_role');
    final logged = _prefs?.getBool('is_logged_in') ?? false;

    final user = currentUser;

    // Handle Admin session check
    if (role == 'admin' && logged) {
      if (user != null && user.email == 'admin@farmcare.ai') {
        return true;
      }
      if (user == null && logged) {
        return true;
      }
      await logout();
      return false;
    }

    if (user == null) {
      return logged;
    }

    // Ensure session is cached locally
    final cachedPhone = _prefs?.getString('logged_user_phone');
    if (cachedPhone == null) {
      final phone = user.phoneNumber?.replaceFirst('+91', '').trim();
      final email = user.email;
      if (phone != null && phone.isNotEmpty) {
        final profile = await getUserProfileByPhone(phone);
        if (profile != null) {
          await _cacheSession(profile.userId, profile.role);
        } else {
          return false;
        }
      } else if (email != null && email.isNotEmpty) {
        final profile = await getUserProfileByEmail(email);
        if (profile != null) {
          await _cacheSession(profile.userId, profile.role);
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }

  Future<String?> getLoggedUserPhone() async {
    await init();
    return currentUser?.uid ?? _prefs?.getString('logged_user_phone');
  }

  Future<String?> getLoggedUserRole() async {
    await init();
    return _prefs!.getString('logged_user_role');
  }

  // Save the full registry locally
  Future<void> _saveRegistry() async {
    final Map<String, dynamic> registryMap = {};
    _userRegistry.forEach((key, value) {
      registryMap[key] = value.toJson();
    });
    await _prefs!.setString('user_registry_json', jsonEncode(registryMap));
  }

  // Backward compatibility signatures
  Future<void> registerUser(String phone, String role) async {
    await init();
    final userId = generateUniqueUserId(role);
    final profile = UserProfile(
      userId: userId,
      role: role,
      password: 'password',
      phone: phone,
      name: 'User ${phone.substring(max(0, phone.length - 4))}',
    );
    _userRegistry[userId] = profile;
    await _saveRegistry();
  }

  Future<String?> getUserRole(String phone) async {
    final profile = await getUserProfileByPhone(phone);
    return profile?.role;
  }
}
