import 'package:flutter/foundation.dart';

class DiagnosticResult {
  final String crop;
  final String diagnosis;
  final double confidence;
  final String healthStatus;
  final List<String> symptoms;
  final List<String> remedies;
  final List<String> organicRemedies;
  final List<String> chemicalRemedies;
  final List<String> suggestedPesticides;
  final List<String> applicationInstructions;

  DiagnosticResult({
    required this.crop,
    required this.diagnosis,
    required this.confidence,
    required this.healthStatus,
    required this.symptoms,
    required this.remedies,
    this.organicRemedies = const [],
    this.chemicalRemedies = const [],
    this.suggestedPesticides = const [],
    this.applicationInstructions = const [],
  });

  Map<String, dynamic> toJson() => {
    'crop': crop,
    'diagnosis': diagnosis,
    'confidence': confidence,
    'healthStatus': healthStatus,
    'symptoms': symptoms,
    'remedies': remedies,
    'organicRemedies': organicRemedies,
    'chemicalRemedies': chemicalRemedies,
    'suggestedPesticides': suggestedPesticides,
    'applicationInstructions': applicationInstructions,
  };

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) => DiagnosticResult(
    crop: json['crop'] as String,
    diagnosis: json['diagnosis'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    healthStatus: json['healthStatus'] as String,
    symptoms: (json['symptoms'] as List?)?.cast<String>() ?? const [],
    remedies: (json['remedies'] as List?)?.cast<String>() ?? const [],
    organicRemedies: (json['organicRemedies'] as List?)?.cast<String>() ?? const [],
    chemicalRemedies: (json['chemicalRemedies'] as List?)?.cast<String>() ?? const [],
    suggestedPesticides: (json['suggestedPesticides'] as List?)?.cast<String>() ?? const [],
    applicationInstructions: (json['applicationInstructions'] as List?)?.cast<String>() ?? const [],
  );
}

class TfliteService {
  static bool get isModelAvailable => false;
  static String? get initializationError => "Offline AI is temporarily disabled (Coming Soon).";

  static Future<void> initializeTflitePipeline() async {
    debugPrint('[TFLITE_SERVICE] Offline TFLite is temporarily disabled (Coming Soon).');
  }

  static Future<TfliteDiagnosticResult?> runRealInference({
    required Uint8List imageBytes,
    required String selectedCrop,
  }) async {
    debugPrint('[TFLITE_SERVICE] Offline TFLite is coming soon.');
    return null;
  }
}

class TfliteDiagnosticResult {
  final String label;
  final double confidence;
  final List<double> allScores;

  TfliteDiagnosticResult({
    required this.label,
    required this.confidence,
    required this.allScores,
  });
}
