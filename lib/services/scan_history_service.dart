import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tflite_service.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'translation_service.dart';

class ScanHistoryRecord {
  final DiagnosticResult result;
  final DateTime timestamp;
  final Uint8List imageBytes;
  final String? imageUrl;
  final String? imagePath;
  final bool isSynced;

  ScanHistoryRecord({
    required this.result,
    required this.timestamp,
    required this.imageBytes,
    this.imageUrl,
    this.imagePath,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'cropName': result.crop,
      'diseaseName': result.diagnosis,
      'confidence': result.confidence,
      'analysisDate': timestamp.millisecondsSinceEpoch,
      'organicRemedy': result.organicRemedies.join(', '),
      'chemicalRemedy': result.chemicalRemedies.join(', '),
      'preventionTips': result.remedies.join(', '),
      'language': TranslationService().currentLanguage.name,
      'imageUrl': imageUrl ?? '',
      'imagePath': imagePath ?? '',
      'localImage': base64Encode(imageBytes),
      'isSynced': isSynced,
    };
  }

  factory ScanHistoryRecord.fromMap(Map<String, dynamic> map) {
    final crop = map['cropName'] ?? 'Unknown Crop';
    final disease = map['diseaseName'] ?? 'Unknown Disease';
    final confidence = (map['confidence'] as num?)?.toDouble() ?? 0.0;
    
    dynamic rawDate = map['analysisDate'];
    DateTime date = DateTime.now();
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    final organicRem = map['organicRemedy'] as String? ?? '';
    final chemicalRem = map['chemicalRemedy'] as String? ?? '';
    final prevention = map['preventionTips'] as String? ?? '';
    final imageUrl = map['imageUrl'] as String? ?? '';
    final imagePath = map['imagePath'] as String? ?? '';
    final isSynced = map['isSynced'] as bool? ?? true;

    final result = DiagnosticResult(
      crop: crop,
      diagnosis: disease,
      confidence: confidence,
      healthStatus: disease.toUpperCase().contains('HEALTHY') || disease.toUpperCase().contains('EXCELLENT') ? 'EXCELLENT' : 'AFFECTED',
      symptoms: [],
      remedies: prevention.isNotEmpty ? prevention.split(', ') : [],
      organicRemedies: organicRem.isNotEmpty ? organicRem.split(', ') : [],
      chemicalRemedies: chemicalRem.isNotEmpty ? chemicalRem.split(', ') : [],
    );

    Uint8List imgBytes = Uint8List(0);
    final localImage = map['localImage'] as String? ?? '';
    if (localImage.isNotEmpty) {
      try {
        imgBytes = base64Decode(localImage);
      } catch (e) {
        debugPrint('[ScanHistoryRecord] Error decoding local image: $e');
      }
    }

    return ScanHistoryRecord(
      result: result,
      timestamp: date,
      imageBytes: imgBytes,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      imagePath: imagePath.isEmpty ? null : imagePath,
      isSynced: isSynced,
    );
  }
}

class ScanHistoryService extends ChangeNotifier {
  static final ScanHistoryService _instance = ScanHistoryService._internal();
  factory ScanHistoryService() => _instance;
  ScanHistoryService._internal();

  final List<ScanHistoryRecord> _records = [];

  List<ScanHistoryRecord> get records => List.unmodifiable(_records);

  Future<void> loadHistory() async {
    final userId = await AuthService().getLoggedUserPhone();
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Populate _records from local cache immediately
    final cachedJson = prefs.getString('scan_history_cache_$userId');
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as List;
        _records.clear();
        for (final item in decoded) {
          _records.add(ScanHistoryRecord.fromMap(Map<String, dynamic>.from(item as Map)));
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[SCAN_HISTORY_SERVICE] Error loading local cache: $e');
      }
    }

    // 2. Try to sync unsynced records
    await _syncUnsynced(userId);

    // 3. Fetch from Firestore
    bool loadedFromFirestore = false;
    List<Map<String, dynamic>> fetchedRecords = [];

    try {
      debugPrint('[SCAN_HISTORY_SERVICE] Fetching scan history from Firestore...');
      fetchedRecords = await FirestoreService().getScanHistory(userId);
      if (fetchedRecords.isNotEmpty) {
        loadedFromFirestore = true;
      }
    } catch (e) {
      debugPrint('[SCAN_HISTORY_SERVICE] Error fetching scan history from Firestore: $e');
    }

    if (loadedFromFirestore) {
      // Merge Firestore records with local unsynced records
      final unsynced = _records.where((r) => !r.isSynced).toList();
      final List<ScanHistoryRecord> merged = List.from(unsynced);

      for (final item in fetchedRecords) {
        final rec = ScanHistoryRecord.fromMap(item);
        // Avoid duplicate records if it matches an unsynced record that just synced
        final isAlreadyAdded = merged.any((r) => 
          r.timestamp.millisecondsSinceEpoch == rec.timestamp.millisecondsSinceEpoch ||
          (r.imageUrl != null && r.imageUrl == rec.imageUrl)
        );
        if (!isAlreadyAdded) {
          // If we have a local cache of image bytes for this remote record, preserve it
          Uint8List cachedImg = Uint8List(0);
          final matchInCache = _records.firstWhere(
            (r) => r.imageUrl == rec.imageUrl || r.timestamp.millisecondsSinceEpoch == rec.timestamp.millisecondsSinceEpoch,
            orElse: () => ScanHistoryRecord(result: rec.result, timestamp: rec.timestamp, imageBytes: Uint8List(0)),
          );
          if (matchInCache.imageBytes.isNotEmpty) {
            cachedImg = matchInCache.imageBytes;
          }

          merged.add(ScanHistoryRecord(
            result: rec.result,
            timestamp: rec.timestamp,
            imageBytes: cachedImg,
            imageUrl: rec.imageUrl,
            imagePath: rec.imagePath,
            isSynced: true,
          ));
        }
      }

      // Sort by date descending
      merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _records.clear();
      _records.addAll(merged);
      notifyListeners();

      // Update local cache
      final serializable = _records.map((r) => r.toMap(userId)).toList();
      await prefs.setString('scan_history_cache_$userId', jsonEncode(serializable));
    }
  }

  Future<void> _syncUnsynced(String userId) async {
    final unsynced = _records.where((r) => !r.isSynced).toList();
    if (unsynced.isEmpty) return;

    debugPrint('[SCAN_HISTORY_SERVICE] Syncing ${unsynced.length} unsynced records...');
    final storage = StorageService();
    final firestore = FirestoreService();
    final prefs = await SharedPreferences.getInstance();

    for (final rec in unsynced) {
      try {
        final timestampMs = rec.timestamp.millisecondsSinceEpoch;
        final scanId = 'scan_$timestampMs';

        // 1. Upload to storage
        final uploadResult = await storage.uploadScanImage(
          userId: userId,
          imageBytes: rec.imageBytes,
          timestamp: timestampMs,
        );

        if (uploadResult != null) {
          final imageUrl = uploadResult['imageUrl']!;
          final imagePath = uploadResult['imagePath']!;

          final recordMap = {
            'userId': userId,
            'cropName': rec.result.crop,
            'diseaseName': rec.result.diagnosis,
            'confidence': rec.result.confidence,
            'analysisDate': Timestamp.fromDate(rec.timestamp),
            'organicRemedy': rec.result.organicRemedies.join(', '),
            'chemicalRemedy': rec.result.chemicalRemedies.join(', '),
            'preventionTips': rec.result.remedies.join(', '),
            'language': TranslationService().currentLanguage.name,
            'imageUrl': imageUrl,
            'imagePath': imagePath,
          };

          // 2. Save to Firestore
          await firestore.saveScanRecord(scanId, recordMap);

          // Update local state
          final idx = _records.indexOf(rec);
          if (idx != -1) {
            _records[idx] = ScanHistoryRecord(
              result: rec.result,
              timestamp: rec.timestamp,
              imageBytes: rec.imageBytes,
              imageUrl: imageUrl,
              imagePath: imagePath,
              isSynced: true,
            );
          }
        }
      } catch (e) {
        debugPrint('[SCAN_HISTORY_SERVICE] Error syncing record: $e');
      }
    }

    // Save updated local list to cache
    final serializedList = _records.map((r) => r.toMap(userId)).toList();
    await prefs.setString('scan_history_cache_$userId', jsonEncode(serializedList));
    notifyListeners();
  }

  void addRecord(DiagnosticResult result, Uint8List imageBytes) {
    final timestamp = DateTime.now();
    final newRecord = ScanHistoryRecord(
      result: result,
      timestamp: timestamp,
      imageBytes: imageBytes,
      isSynced: false, // Initial state before uploading
    );
    _records.insert(0, newRecord);
    notifyListeners();

    _saveRecordAsync(newRecord, imageBytes, timestamp);
  }

  Future<void> _saveRecordAsync(ScanHistoryRecord localRec, Uint8List imageBytes, DateTime timestamp) async {
    try {
      final userId = await AuthService().getLoggedUserPhone() ?? 'anonymous';
      final timestampMs = timestamp.millisecondsSinceEpoch;
      final scanId = 'scan_$timestampMs';

      // 1. Attempt upload
      final uploadResult = await StorageService().uploadScanImage(
        userId: userId,
        imageBytes: imageBytes,
        timestamp: timestampMs,
      );

      String? imageUrl;
      String? imagePath;
      bool synced = false;

      if (uploadResult != null) {
        imageUrl = uploadResult['imageUrl'];
        imagePath = uploadResult['imagePath'];
        synced = true;

        final recordMap = {
          'userId': userId,
          'cropName': localRec.result.crop,
          'diseaseName': localRec.result.diagnosis,
          'confidence': localRec.result.confidence,
          'analysisDate': Timestamp.fromDate(timestamp),
          'organicRemedy': localRec.result.organicRemedies.join(', '),
          'chemicalRemedy': localRec.result.chemicalRemedies.join(', '),
          'preventionTips': localRec.result.remedies.join(', '),
          'language': TranslationService().currentLanguage.name,
          'imageUrl': imageUrl,
          'imagePath': imagePath,
        };

        // 2. Write to Firestore
        await FirestoreService().saveScanRecord(scanId, recordMap);
      }

      // Update in-memory record sync state
      final idx = _records.indexWhere((r) => r.timestamp.millisecondsSinceEpoch == timestampMs);
      if (idx != -1) {
        _records[idx] = ScanHistoryRecord(
          result: localRec.result,
          timestamp: localRec.timestamp,
          imageBytes: localRec.imageBytes,
          imageUrl: imageUrl,
          imagePath: imagePath,
          isSynced: synced,
        );
        notifyListeners();
      }

      // 3. Write to SharedPreferences local cache
      final prefs = await SharedPreferences.getInstance();
      final serializable = _records.map((r) => r.toMap(userId)).toList();
      await prefs.setString('scan_history_cache_$userId', jsonEncode(serializable));
      debugPrint('[SCAN_HISTORY_SERVICE] Saved scan record (synced: $synced) to local cache.');
    } catch (e) {
      debugPrint('[SCAN_HISTORY_SERVICE] Error saving scan record asynchronously: $e');
    }
  }

  void deleteRecord(ScanHistoryRecord record) {
    _records.remove(record);
    notifyListeners();
    _deleteRecordAsync(record);
  }

  Future<void> _deleteRecordAsync(ScanHistoryRecord record) async {
    try {
      final userId = await AuthService().getLoggedUserPhone();
      if (userId == null) return;

      // 1. Delete Firestore document
      final timestampMs = record.timestamp.millisecondsSinceEpoch;
      await FirebaseFirestore.instance.collection('scan_history').doc('scan_$timestampMs').delete();

      // 2. Delete Storage image
      if (record.isSynced && record.imagePath != null && record.imagePath!.isNotEmpty) {
        await StorageService().deleteScanImage(record.imagePath!);
      }

      // 3. Update SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final serializable = _records.map((r) => r.toMap(userId)).toList();
      await prefs.setString('scan_history_cache_$userId', jsonEncode(serializable));
      debugPrint('[SCAN_HISTORY_SERVICE] Successfully deleted record scan_$timestampMs.');
    } catch (e) {
      debugPrint('[SCAN_HISTORY_SERVICE] Error deleting record: $e');
    }
  }

  void clearHistory() {
    final toDelete = List<ScanHistoryRecord>.from(_records);
    _records.clear();
    notifyListeners();
    _clearHistoryAsync(toDelete);
  }

  Future<void> _clearHistoryAsync(List<ScanHistoryRecord> recordsToDelete) async {
    try {
      final userId = await AuthService().getLoggedUserPhone();
      if (userId == null) return;

      final firestore = FirebaseFirestore.instance;
      final storage = StorageService();

      final batch = firestore.batch();
      for (final rec in recordsToDelete) {
        final timestampMs = rec.timestamp.millisecondsSinceEpoch;
        batch.delete(firestore.collection('scan_history').doc('scan_$timestampMs'));

        if (rec.isSynced && rec.imagePath != null && rec.imagePath!.isNotEmpty) {
          await storage.deleteScanImage(rec.imagePath!);
        }
      }
      await batch.commit();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scan_history_cache_$userId');
      debugPrint('[SCAN_HISTORY_SERVICE] Cleared all scan history from Firestore, Storage, and cache.');
    } catch (e) {
      debugPrint('[SCAN_HISTORY_SERVICE] Error clearing history: $e');
    }
  }
}
