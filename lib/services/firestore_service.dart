import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save or update user profile details
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String phone,
    required String role,
    String? email,
    String? village,
    String? district,
    String? shopName,
    String? address,
  }) async {
    try {
      final docRef = _db.collection('users').doc(userId);
      final data = {
        'name': name,
        'phone': phone,
        'role': role,
        if (email != null) 'email': email,
        if (village != null) 'village': village,
        if (district != null) 'district': district,
        if (shopName != null) 'shopName': shopName,
        if (address != null) 'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved user profile: $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving user profile: $e');
    }
  }

  // Get user profile details
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error loading user profile: $e');
    }
    return null;
  }

  // Save or update my_farm record in Firestore
  Future<void> saveMyFarm({
    required String userId,
    required String cropName,
    required String acreage,
    required int sowingDate,
    required List<Map<String, dynamic>> fertilizerSchedule,
    required List<Map<String, dynamic>> spraySchedule,
    required List<Map<String, dynamic>> inspectionSchedule,
    required String harvestEstimate,
  }) async {
    try {
      final docRef = _db.collection('my_farm').doc(userId);
      final data = {
        'cropName': cropName,
        'acreage': acreage,
        'sowingDate': sowingDate,
        'fertilizerSchedule': fertilizerSchedule,
        'spraySchedule': spraySchedule,
        'inspectionSchedule': inspectionSchedule,
        'harvestEstimate': harvestEstimate,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved my_farm details for: $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving my_farm details: $e');
      rethrow;
    }
  }

  // Get my_farm record from Firestore
  Future<Map<String, dynamic>?> getMyFarm(String userId) async {
    try {
      final doc = await _db.collection('my_farm').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error loading my_farm details: $e');
    }
    return null;
  }

  // --- Community Collection Methods ---

  // Save/Update community post
  Future<void> saveCommunityPost(String postId, Map<String, dynamic> data) async {
    try {
      await _db.collection('community_posts').doc(postId).set(data, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved community post: $postId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving community post: $e');
    }
  }

  // Save a reply under community_posts/{postId}/replies/{replyId}
  Future<void> saveCommunityReply(String postId, String replyId, Map<String, dynamic> data) async {
    try {
      await _db.collection('community_posts').doc(postId).collection('replies').doc(replyId).set(data, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved reply $replyId under post $postId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving community reply: $e');
    }
  }

  // Get replies for a post ordered by createdAt ascending
  Future<List<Map<String, dynamic>>> getCommunityReplies(String postId) async {
    try {
      final snapshot = await _db.collection('community_posts').doc(postId).collection('replies').get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['replyId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return aTime.compareTo(bTime);
      });
      return list;
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching community replies: $e');
      return [];
    }
  }

  // Get all community posts ordered by createdAt descending
  Future<List<Map<String, dynamic>>> getCommunityPosts() async {
    try {
      final snapshot = await _db.collection('community_posts').get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching community posts: $e');
      return [];
    }
  }

  // --- Notifications Collection Methods ---

  // Save/Update notification
  Future<void> saveNotification(String notificationId, Map<String, dynamic> data) async {
    try {
      await _db.collection('notifications').doc(notificationId).set(data, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved notification: $notificationId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving notification: $e');
    }
  }

  // Get notifications for a user (global and personal) ordered by createdAt descending
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      // 1. Get global notifications
      final globalSnapshot = await _db.collection('notifications')
          .where('userId', isEqualTo: 'ALL')
          .get();

      // 2. Get personal notifications
      final personalSnapshot = await _db.collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> allNotifs = [];

      for (final doc in globalSnapshot.docs) {
        final data = doc.data();
        data['notificationId'] = doc.id;
        allNotifs.add(data);
      }

      for (final doc in personalSnapshot.docs) {
        final data = doc.data();
        data['notificationId'] = doc.id;
        allNotifs.add(data);
      }

      // Sort by createdAt descending
      allNotifs.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });

      return allNotifs;
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching notifications: $e');
      return [];
    }
  }

  // --- Scanner History Collection Methods ---

  // Save scan record
  Future<void> saveScanRecord(String scanId, Map<String, dynamic> data) async {
    try {
      await _db.collection('scan_history').doc(scanId).set(data, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved scan record: $scanId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving scan record: $e');
    }
  }

  // Get scan history for user ordered by analysisDate descending
  Future<List<Map<String, dynamic>>> getScanHistory(String userId) async {
    try {
      final snapshot = await _db.collection('scan_history')
          .where('userId', isEqualTo: userId)
          .get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['scanId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['analysisDate']);
        final bTime = _parseTime(b['analysisDate']);
        return bTime.compareTo(aTime);
      });
      return list;
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching scan history: $e');
      return [];
    }
  }

  // --- Products Collection ---

  Stream<List<Map<String, dynamic>>> getProductsStream(String? category) {
    Query<Map<String, dynamic>> query = _db.collection('products');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Stream of products registered by a specific shop owner
  Stream<List<Map<String, dynamic>>> getShopProductsStream(String shopId) {
    return _db.collection('products')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Save or update product details (inventory management)
  Future<void> saveProduct(String productId, Map<String, dynamic> data) async {
    try {
      final docRef = _db.collection('products').doc(productId);
      await docRef.set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved product: $productId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving product: $e');
      rethrow;
    }
  }

  // Update specific stock or price of a product
  Future<void> updateProductStockOrPrice(String productId, {double? price, int? stock}) async {
    try {
      final docRef = _db.collection('products').doc(productId);
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (price != null) updates['price'] = price;
      if (stock != null) updates['stock'] = stock;

      await docRef.update(updates);
      debugPrint('[FIRESTORE_SERVICE] Updated product stock/price: $productId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating product stock/price: $e');
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted product: $productId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting product: $e');
      rethrow;
    }
  }

  // --- Carts Collection ---

  // Get stream of a user's cart
  Stream<Map<String, dynamic>?> getCartStream(String userId) {
    return _db.collection('carts').doc(userId).snapshots().map((doc) => doc.data());
  }

  // Save the full list of items in a user's cart
  Future<void> saveCart(String userId, List<Map<String, dynamic>> items) async {
    try {
      final docRef = _db.collection('carts').doc(userId);
      await docRef.set({
        'userId': userId,
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Saved cart for user: $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving cart: $e');
      rethrow;
    }
  }

  // Clear cart
  Future<void> clearCart(String userId) async {
    try {
      await _db.collection('carts').doc(userId).delete();
      debugPrint('[FIRESTORE_SERVICE] Cleared cart for user: $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error clearing cart: $e');
      rethrow;
    }
  }

  // --- Orders Collection ---

  // Place order
  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final docRef = _db.collection('orders').doc();
      await docRef.set({
        ...orderData,
        'orderId': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Placed order: ${docRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error placing order: $e');
      rethrow;
    }
  }

  // Stream of orders placed by a specific farmer
  Stream<List<Map<String, dynamic>>> getFarmerOrdersStream(String farmerId) {
    return _db.collection('orders')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Stream of incoming orders for a specific shop owner
  Stream<List<Map<String, dynamic>>> getShopOrdersStream(String shopId) {
    return _db.collection('orders')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Updated order $orderId to: $status');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating order status: $e');
      rethrow;
    }
  }

  // --- Crop Offers Collection ---

  // Post crop offer
  Future<void> postCropOffer(Map<String, dynamic> offerData) async {
    try {
      final docRef = _db.collection('crop_offers').doc();
      await docRef.set({
        ...offerData,
        'offerId': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Posted crop offer: ${docRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error posting crop offer: $e');
      rethrow;
    }
  }

  // Stream of crop offers posted by a specific farmer
  Stream<List<Map<String, dynamic>>> getFarmerCropOffersStream(String farmerId) {
    return _db.collection('crop_offers')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['offerId'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Stream of all crop offers (e.g. for Shop Owners to browse and accept)
  Stream<List<Map<String, dynamic>>> getCropOffersStream() {
    return _db.collection('crop_offers')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['offerId'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Update crop offer status
  Future<void> updateCropOfferStatus(String offerId, String status, {String? shopId}) async {
    try {
      final Map<String, dynamic> updates = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (shopId != null) {
        updates['acceptedBy'] = shopId;
      }
      await _db.collection('crop_offers').doc(offerId).update(updates);
      debugPrint('[FIRESTORE_SERVICE] Updated crop offer $offerId to: $status');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating crop offer status: $e');
      rethrow;
    }
  }

  // Accept a crop offer (write transaction document under purchases, update status)
  Future<void> acceptCropOffer(String offerId, String shopId, Map<String, dynamic> purchaseData) async {
    try {
      final purchaseRef = _db.collection('purchases').doc();
      final batch = _db.batch();

      // Update offer status
      batch.update(_db.collection('crop_offers').doc(offerId), {
        'status': 'ACCEPTED',
        'acceptedBy': shopId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Write transaction purchase
      batch.set(purchaseRef, {
        ...purchaseData,
        'purchaseId': purchaseRef.id,
        'offerId': offerId,
        'shopId': shopId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('[FIRESTORE_SERVICE] Accepted crop offer $offerId and created purchase ${purchaseRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error accepting crop offer: $e');
      rethrow;
    }
  }

  // Stream of purchases registered by a specific shop owner
  Stream<List<Map<String, dynamic>>> getShopPurchasesStream(String shopId) {
    return _db.collection('purchases')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['purchaseId'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Negotiate crop offer counter-price
  Future<void> negotiateCropOffer(String offerId, double counterPrice, String shopId, {String? shopName}) async {
    try {
      await _db.collection('crop_offers').doc(offerId).update({
        'status': 'NEGOTIATING',
        'counterPricePerKg': counterPrice,
        'negotiatedBy': shopId,
        if (shopName != null) 'shopName': shopName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Counter offer submitted for $offerId: ₹$counterPrice/kg');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error negotiating crop offer: $e');
      rethrow;
    }
  }

  // Assign machine and driver for machinery rental request
  Future<void> assignMachineryRental(String requestId, {
    required String machineId,
    required String machineName,
    required String driverName,
    required String driverPhone,
  }) async {
    try {
      await _db.collection('machinery_requests').doc(requestId).update({
        'status': 'Assigned',
        'assignedMachineId': machineId,
        'assignedMachineName': machineName,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Assigned machine $machineName & driver $driverName to request $requestId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error assigning machinery rental: $e');
      rethrow;
    }
  }

  // Update machinery request stage workflow
  Future<void> updateMachineryRequestWorkflow(String requestId, String status, {double? paymentAmount}) async {
    try {
      final Map<String, dynamic> updates = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (paymentAmount != null) {
        updates['paymentAmount'] = paymentAmount;
        updates['paymentStatus'] = 'PAID';
      }
      await _db.collection('machinery_requests').doc(requestId).update(updates);
      debugPrint('[FIRESTORE_SERVICE] Updated machinery request $requestId status to: $status');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating machinery request workflow: $e');
      rethrow;
    }
  }

  Future<void> createNotification(Map<String, dynamic> notifData) async {
    try {
      final docRef = _db.collection('notifications').doc();
      await docRef.set({
        ...notifData,
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Created notification: ${docRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error creating notification: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _db.collection('notifications').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> getCommunityPostsStream() {
    return _db.collection('community_posts').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  // Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error marking notification read: $e');
    }
  }

  // Mark all notifications read for user
  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final snapshot = await _db.collection('notifications')
          .where('userId', whereIn: [userId, 'ALL'])
          .get();
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error marking all notifications read: $e');
    }
  }

  // --- Admin Analytics Data Queries ---

  // Get all orders from Firestore (one-time fetch)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final snapshot = await _db.collection('orders').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching all orders: $e');
      return [];
    }
  }

  // Get all purchases from Firestore (one-time fetch)
  Future<List<Map<String, dynamic>>> getAllPurchases() async {
    try {
      final snapshot = await _db.collection('purchases').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['purchaseId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching all purchases: $e');
      return [];
    }
  }

  // Get all scan history records from Firestore (one-time fetch for Admin)
  Future<List<Map<String, dynamic>>> getAllScanHistory() async {
    try {
      final snapshot = await _db.collection('scan_history').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['scanId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching all scan history: $e');
      return [];
    }
  }

  // --- Soil Reports Collection ---

  // Save Soil Report
  Future<void> saveSoilReport(String userId, Map<String, dynamic> reportData) async {
    try {
      final docRef = _db.collection('soil_reports').doc();
      await docRef.set({
        ...reportData,
        'reportId': docRef.id,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Saved soil report: ${docRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving soil report: $e');
      rethrow;
    }
  }

  // Stream Soil Reports
  Stream<List<Map<String, dynamic>>> getSoilReportsStream(String userId) {
    return _db.collection('soil_reports')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['reportId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  // Delete Soil Report
  Future<void> deleteSoilReport(String reportId) async {
    try {
      await _db.collection('soil_reports').doc(reportId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted soil report: $reportId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting soil report: $e');
      rethrow;
    }
  }

  // --- Crop Plans Collection ---

  Future<void> saveCropPlan(String userId, Map<String, dynamic> planData) async {
    try {
      final docRef = _db.collection('crop_plans').doc();
      await docRef.set({
        ...planData,
        'planId': docRef.id,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Saved crop plan: ${docRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving crop plan: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getCropPlansStream(String userId) {
    return _db.collection('crop_plans')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['planId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> deleteCropPlan(String planId) async {
    try {
      await _db.collection('crop_plans').doc(planId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted crop plan: $planId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting crop plan: $e');
      rethrow;
    }
  }

  // --- Fertilizer Recommendations Collection ---

  Future<void> saveFertilizerRecommendation(String userId, Map<String, dynamic> recData) async {
    try {
      final docRef = _db.collection('fertilizer_recommendations').doc();
      await docRef.set({
        ...recData,
        'recId': docRef.id,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Saved fertilizer recommendation: ${docRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving fertilizer recommendation: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getFertilizerRecommendationsStream(String userId) {
    return _db.collection('fertilizer_recommendations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['recId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> deleteFertilizerRecommendation(String recId) async {
    try {
      await _db.collection('fertilizer_recommendations').doc(recId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted fertilizer recommendation: $recId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting fertilizer recommendation: $e');
      rethrow;
    }
  }

  // --- Machinery Requests Collection ---

  Future<void> saveMachineryRequest(Map<String, dynamic> requestData) async {
    try {
      final docRef = _db.collection('machinery_requests').doc();
      await docRef.set({
        ...requestData,
        'requestId': docRef.id,
        'status': requestData['status'] ?? 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Saved machinery request: ${docRef.id}');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving machinery request: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getFarmerMachineryRequestsStream(String farmerId) {
    return _db.collection('machinery_requests')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> getShopMachineryRequestsStream() {
    return _db.collection('machinery_requests')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> updateMachineryRequestStatus(String requestId, String status) async {
    try {
      await _db.collection('machinery_requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Updated machinery request $requestId status to: $status');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating machinery request status: $e');
      rethrow;
    }
  }

  // --- Machinery Inventory Collection ---

  Future<void> saveMachineryItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      final docRef = _db.collection('machinery_inventory').doc(itemId);
      await docRef.set({
        ...itemData,
        'itemId': itemId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FIRESTORE_SERVICE] Saved machinery inventory item: $itemId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving machinery inventory item: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getMachineryInventoryStream(String? shopId) {
    Query<Map<String, dynamic>> query = _db.collection('machinery_inventory');
    if (shopId != null && shopId.isNotEmpty) {
      query = query.where('shopId', isEqualTo: shopId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['itemId'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> deleteMachineryItem(String itemId) async {
    try {
      await _db.collection('machinery_inventory').doc(itemId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted machinery item: $itemId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting machinery item: $e');
      rethrow;
    }
  }

  // --- Multi-Crop Farm Collection ---

  Future<void> saveFarmCrop(String userId, Map<String, dynamic> cropData) async {
    try {
      final docRef = _db.collection('farms').doc(userId).collection('crops').doc();
      await docRef.set({
        ...cropData,
        'cropId': docRef.id,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Saved farm crop: ${docRef.id} for user: $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving farm crop: $e');
      rethrow;
    }
  }

  Future<void> updateFarmCrop(String userId, String cropId, Map<String, dynamic> cropData) async {
    try {
      await _db.collection('farms').doc(userId).collection('crops').doc(cropId).update({
        ...cropData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Updated farm crop: $cropId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating farm crop: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getFarmCropsStream(String userId) {
    return _db.collection('farms')
        .doc(userId)
        .collection('crops')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['cropId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> deleteFarmCrop(String userId, String cropId) async {
    try {
      await _db.collection('farms').doc(userId).collection('crops').doc(cropId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted farm crop $cropId for user $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting farm crop: $e');
      rethrow;
    }
  }

  // --- AI Chat History Collection ---

  Future<void> saveAiChatMessage(String userId, String text, bool isBot, {bool isError = false}) async {
    try {
      final docRef = _db.collection('ai_chat_history').doc();
      await docRef.set({
        'msgId': docRef.id,
        'userId': userId,
        'text': text,
        'isBot': isBot,
        'isError': isError,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Saved AI chat message for $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving AI chat message: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAiChatHistoryStream(String userId) {
    return _db.collection('ai_chat_history')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['msgId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['createdAt']);
        final bTime = _parseTime(b['createdAt']);
        return aTime.compareTo(bTime);
      });
      return list;
    });
  }

  Future<void> clearAiChatHistory(String userId) async {
    try {
      final snapshot = await _db.collection('ai_chat_history').where('userId', isEqualTo: userId).get();
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[FIRESTORE_SERVICE] Cleared AI chat history for $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error clearing AI chat history: $e');
    }
  }

  // --- Login History Collection ---

  Future<void> saveLoginRecord({
    required String uid,
    required String name,
    required String role,
    String? email,
    String? platform,
    String? deviceName,
  }) async {
    try {
      final docRef = _db.collection('login_history').doc();
      await docRef.set({
        'historyId': docRef.id,
        'uid': uid,
        'name': name,
        'email': email ?? '',
        'role': role,
        'loginTime': FieldValue.serverTimestamp(),
        'logoutTime': null,
        'platform': platform ?? (kIsWeb ? 'Web' : 'Android'),
        'deviceName': deviceName ?? 'Default Device',
        'status': 'Active',
      });
      debugPrint('[FIRESTORE_SERVICE] Saved login record for $uid');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error saving login record: $e');
    }
  }

  Future<void> updateLogoutRecord(String uid) async {
    try {
      final snapshot = await _db.collection('login_history')
          .where('uid', isEqualTo: uid)
          .where('status', isEqualTo: 'Active')
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'logoutTime': FieldValue.serverTimestamp(),
          'status': 'Logged Out',
        });
      }
      debugPrint('[FIRESTORE_SERVICE] Updated logout record for $uid');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating logout record: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getLoginHistoryStream() {
    return _db.collection('login_history').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['historyId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['loginTime']);
        final bTime = _parseTime(b['loginTime']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  // --- Audit Logs Collection ---

  Future<void> logAuditEvent({
    required String userId,
    String? userName,
    required String action,
    required String category,
    String? details,
  }) async {
    try {
      final docRef = _db.collection('audit_logs').doc();
      await docRef.set({
        'logId': docRef.id,
        'userId': userId,
        'userName': userName ?? 'User $userId',
        'action': action,
        'category': category,
        'details': details ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Audit log added: $action ($category)');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error adding audit log: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAuditLogsStream() {
    return _db.collection('audit_logs').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['logId'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = _parseTime(a['timestamp']);
        final bTime = _parseTime(b['timestamp']);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  // --- User Administration & Moderation Methods ---

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching all users: $e');
      return [];
    }
  }

  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _db.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Updated user $userId status to $status');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating user status: $e');
      rethrow;
    }
  }

  Future<void> deleteUserDoc(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted user doc $userId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting user doc: $e');
      rethrow;
    }
  }

  Future<void> updateShopVerificationStatus(String userId, String status) async {
    try {
      await _db.collection('users').doc(userId).update({
        'verificationStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FIRESTORE_SERVICE] Updated shop verification $userId to $status');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error updating shop verification: $e');
      rethrow;
    }
  }

  Future<void> deleteCommunityPost(String postId) async {
    try {
      await _db.collection('community_posts').doc(postId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted community post $postId');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting community post: $e');
    }
  }

  Future<void> pinOrFeatureCommunityPost(String postId, {bool? isPinned, bool? isFeatured}) async {
    try {
      final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (isPinned != null) updates['isPinned'] = isPinned;
      if (isFeatured != null) updates['isFeatured'] = isFeatured;
      await _db.collection('community_posts').doc(postId).update(updates);
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error pinning/featuring community post: $e');
    }
  }

  // --- Generic Firestore Explorer Helper ---

  Future<List<Map<String, dynamic>>> getCollectionDocs(String collectionName) async {
    try {
      final snapshot = await _db.collection(collectionName).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['_docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error fetching collection docs for $collectionName: $e');
      return [];
    }
  }

  Future<void> deleteCollectionDoc(String collectionName, String docId) async {
    try {
      await _db.collection(collectionName).doc(docId).delete();
      debugPrint('[FIRESTORE_SERVICE] Deleted doc $docId from $collectionName');
    } catch (e) {
      debugPrint('[FIRESTORE_SERVICE] Error deleting doc $docId from $collectionName: $e');
    }
  }

  // --- Helper Methods ---

  int _parseTime(dynamic val) {
    if (val is Timestamp) {
      return val.millisecondsSinceEpoch;
    } else if (val is int) {
      return val;
    } else if (val is String) {
      return DateTime.tryParse(val)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }
}
