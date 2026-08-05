import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload crop scanner image to scan_images/{userId}/{timestamp}.jpg
  // Returns a Map with 'imageUrl' and 'imagePath'
  Future<Map<String, String>?> uploadScanImage({
    required String userId,
    required Uint8List imageBytes,
    required int timestamp,
  }) async {
    try {
      final imagePath = 'scan_images/$userId/$timestamp.jpg';
      final ref = _storage.ref().child(imagePath);

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('[STORAGE_SERVICE] Scanned image uploaded: $downloadUrl');
      return {
        'imageUrl': downloadUrl,
        'imagePath': imagePath,
      };
    } catch (e) {
      debugPrint('[STORAGE_SERVICE] Error uploading scanned image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage using its path
  Future<void> deleteScanImage(String imagePath) async {
    try {
      if (imagePath.isEmpty) return;
      final ref = _storage.ref().child(imagePath);
      await ref.delete();
      debugPrint('[STORAGE_SERVICE] Deleted scanned image: $imagePath');
    } catch (e) {
      debugPrint('[STORAGE_SERVICE] Error deleting image $imagePath: $e');
    }
  }
}
