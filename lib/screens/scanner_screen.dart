import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/tflite_service.dart';
import '../services/gemini_service.dart';
import '../services/scan_history_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScanHistoryService _historyService = ScanHistoryService();
  final TextEditingController _apiKeyController = TextEditingController();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  
  bool _isAnalyzing = false;
  DiagnosticResult? _diagnosticResult;
  bool _isOnlineMode = true; // Default to Online AI (Gemini)
  bool _showSettings = false;

  int _activeResultTab = 0;

  // Persistence/verification variables for API Key
  String? _savedApiKey;
  bool _isEditingApiKey = false;
  bool _isTestingKey = false;
  bool? _lastConnectionTestResult;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('[CROP_SCANNER] Platform detected: ${kIsWeb ? "Web Chrome" : "Mobile Native"}');
    
    // Load saved API Key from SharedPreferences
    _loadSavedApiKey();

    // Try to load TFLite model in background for offline options
    TfliteService.initializeTflitePipeline();
    
    // Listen to history updates
    _historyService.addListener(_onHistoryChanged);
    _historyService.loadHistory();

    // Listen to API key input changes
    _apiKeyController.addListener(_onApiKeyChanged);
  }

  void _onHistoryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      setState(() {
        _savedApiKey = savedKey;
        _apiKeyController.text = savedKey;
      });
      // Verify saved key in background
      final bool isConnected = await GeminiService.testApiKey(savedKey);
      if (mounted) {
        setState(() {
          _lastConnectionTestResult = isConnected;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _showSettings = true; // Automatically expand settings for setup if no key exists
        });
      }
    }
  }

  void _onApiKeyChanged() {
    final String key = _apiKeyController.text.trim();
    _debounceTimer?.cancel();

    if (_isValidApiKey(key)) {
      _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
        _saveAndTestApiKey(key);
      });
    }
  }

  Future<void> _saveAndTestApiKey(String key) async {
    if (key == _savedApiKey && _lastConnectionTestResult == true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    
    if (mounted) {
      setState(() {
        _savedApiKey = key;
        _isTestingKey = true;
        _lastConnectionTestResult = null;
      });
    }

    debugPrint('[CROP_SCANNER] Performing Gemini connectivity test...');
    final bool isConnected = await GeminiService.testApiKey(key);
    
    if (mounted) {
      setState(() {
        _isTestingKey = false;
        _lastConnectionTestResult = isConnected;
        if (isConnected) {
          _isEditingApiKey = false;
        }
      });
    }
  }

  bool _isValidApiKey(String key) {
    final k = key.trim();
    return k.isNotEmpty && k.length >= 10;
  }

  String _obfuscateApiKey(String key) {
    if (key.length <= 9) {
      return '*' * key.length;
    }
    return '${key.substring(0, 7)}***********${key.substring(key.length - 2)}';
  }

  void _changeApiKey() {
    setState(() {
      _isEditingApiKey = true;
      _lastConnectionTestResult = null;
    });
  }

  Future<void> _removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    setState(() {
      _savedApiKey = null;
      _apiKeyController.clear();
      _isEditingApiKey = false;
      _lastConnectionTestResult = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API Key removed. Please configure a new one.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final String key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isTestingKey = true;
    });

    final bool isConnected = await GeminiService.testApiKey(key);

    if (mounted) {
      setState(() {
        _isTestingKey = false;
        _lastConnectionTestResult = isConnected;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isConnected ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(isConnected ? '✓ Gemini Connected' : '✗ Invalid API Key'),
            ],
          ),
          backgroundColor: isConnected ? AppTheme.primaryGreen : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStatusIndicator() {
    final bool hasKey = _savedApiKey != null && _savedApiKey!.isNotEmpty;
    final bool isConnected = hasKey && (_lastConnectionTestResult != false);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isConnected 
                ? Colors.green.withValues(alpha: 0.1) 
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected ? Colors.green : Colors.red,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '● ',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
              Text(
                isConnected ? 'Gemini Connected' : 'Gemini Not Configured',
                style: TextStyle(
                  color: isConnected ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: AppTheme.accentGold, size: 22),
              const SizedBox(width: 8),
              Text(
                'First-Time Setup',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your Gemini API key once. It will be saved securely on this device.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Enter Gemini API Key',
              prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18, color: AppTheme.primaryGreen),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              ),
            ),
          ),
          if (_isTestingKey) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                ),
                SizedBox(width: 8),
                Text(
                  'Verifying API key...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ] else if (_lastConnectionTestResult != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _lastConnectionTestResult == true 
                      ? Icons.check_circle_rounded 
                      : Icons.cancel_rounded,
                  color: _lastConnectionTestResult == true ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _lastConnectionTestResult == true 
                      ? '✓ Gemini Connected' 
                      : '✗ Invalid API Key',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _lastConnectionTestResult == true ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Gemini API Key',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Enter Gemini API Key',
              prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18, color: AppTheme.primaryGreen),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingApiKey = false;
                    _apiKeyController.text = _savedApiKey ?? '';
                    _lastConnectionTestResult = _savedApiKey != null;
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: _isTestingKey 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isTestingKey ? null : _testConnection,
              ),
            ],
          ),
          if (_lastConnectionTestResult != null && !_isTestingKey) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _lastConnectionTestResult == true 
                      ? Icons.check_circle_rounded 
                      : Icons.cancel_rounded,
                  color: _lastConnectionTestResult == true ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _lastConnectionTestResult == true 
                      ? '✓ Gemini Connected' 
                      : '✗ Invalid API Key',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _lastConnectionTestResult == true ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    final bool isConnected = _lastConnectionTestResult != false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected 
            ? AppTheme.primaryGreen.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected 
              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isConnected ? AppTheme.primaryGreen : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Gemini AI Connected' : 'Gemini Connection Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isConnected ? AppTheme.primaryGreen : Colors.red[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _obfuscateApiKey(_savedApiKey ?? ''),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[650],
                  ),
                ),
              ],
            ),
          ),
          _buildSettingsDropdownButton(),
        ],
      ),
    );
  }

  Widget _buildSettingsDropdownButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
      tooltip: 'Gemini Key Settings',
      onSelected: (value) {
        if (value == 'change') {
          _changeApiKey();
        } else if (value == 'remove') {
          _removeApiKey();
        } else if (value == 'test') {
          _testConnection();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'change',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: Colors.black54),
              SizedBox(width: 8),
              Text('Change API Key'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'test',
          child: Row(
            children: [
              Icon(Icons.wifi_rounded, size: 18, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Test Connection'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Remove API Key', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _historyService.removeListener(_onHistoryChanged);
    _apiKeyController.removeListener(_onApiKeyChanged);
    _apiKeyController.dispose();
    TtsService.stop();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final String sourceName = source == ImageSource.camera ? 'Camera' : 'Gallery';
    debugPrint('[CROP_SCANNER] User selected: $sourceName');

    try {
      final XFile? selectedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (selectedFile != null) {
        final Uint8List bytes = await selectedFile.readAsBytes();
        setState(() {
          _imageFile = selectedFile;
          _imageBytes = bytes;
          _diagnosticResult = null; // Clear previous diagnoses
        });
        debugPrint('[CROP_SCANNER] Image received! size: ${bytes.length} bytes.');
      } else {
        debugPrint('[CROP_SCANNER] Selection cancelled.');
      }
    } catch (e) {
      debugPrint('[CROP_SCANNER] Exception picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing camera/gallery: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _clearImage() {
    TtsService.stop();
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _diagnosticResult = null;
    });
    debugPrint('[CROP_SCANNER] Reset complete.');
  }

  Future<void> _analyzeImage() async {
    final trans = TranslationService();
    TtsService.stop();
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select or capture a crop leaf photo first!'),
            ],
          ),
          backgroundColor: AppTheme.accentGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isOnlineMode) {
      // Run Online Gemini Vision AI
      final String apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        setState(() {
          _showSettings = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your Gemini API Key in the settings panel to run Online AI.'),
            backgroundColor: AppTheme.accentGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _isAnalyzing = true;
        _diagnosticResult = null;
      });

      try {
        final result = await GeminiService.analyzeImageWithGemini(
          imageBytes: _imageBytes!,
          customApiKey: apiKey,
        );

        setState(() {
          _diagnosticResult = result;
          _isAnalyzing = false;
        });

        // Store result in Scan History
        _historyService.addRecord(result, _imageBytes!);

        final String speakText = '${result.crop} - ${result.diagnosis}. '
            '${result.symptoms.isNotEmpty ? "${trans.translate('symptoms_label')}: ${result.symptoms.join(". ")}" : ""}. '
            '${result.remedies.isNotEmpty ? "${trans.translate('remedies_label')}: ${result.remedies.join(". ")}" : ""}';
        TtsService.speak(speakText);

      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } else {
      // Run Offline TFLite AI
      if (!TfliteService.isModelAvailable) {
        _showModelNotInstalledDialog();
        return;
      }

      setState(() {
        _isAnalyzing = true;
        _diagnosticResult = null;
      });

      // Simulate computational delay
      await Future.delayed(const Duration(milliseconds: 2000));

      final tfliteResult = await TfliteService.runRealInference(
        imageBytes: _imageBytes!,
        selectedCrop: '',
      );

      setState(() {
        _isAnalyzing = false;
      });

      if (tfliteResult == null) {
        _showModelNotInstalledDialog();
      } else {
        final result = DiagnosticResult(
          crop: 'Unknown Crop',
          diagnosis: tfliteResult.label,
          confidence: tfliteResult.confidence,
          healthStatus: tfliteResult.confidence > 80.0 ? 'EXCELLENT' : 'CRITICAL',
          symptoms: [
            'Detected class label: ${tfliteResult.label}.',
            'Model confidence: ${tfliteResult.confidence.toStringAsFixed(2)}%.'
          ],
          remedies: [
            'Confirm disease symptoms with local extension officers.',
            'Maintain strict crop spacing and dry leaf laminae.'
          ],
        );

        setState(() {
          _diagnosticResult = result;
        });

        // Store in Scan History
        _historyService.addRecord(result, _imageBytes!);
      }
    }
  }

  void _showModelNotInstalledDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.offline_bolt_rounded,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Offline AI Coming Soon',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Offline TFLite classification is temporarily disabled and coming soon! Please switch to Online AI (Gemini) for instant, dynamic leaf disease analysis.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I Understand',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHistoryBottomSheet() {
    final trans = TranslationService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final records = _historyService.records;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        trans.translate('scan_history'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                      const Spacer(),
                      if (records.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _historyService.clearHistory();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Scan History cleared.')),
                            );
                          },
                          child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (records.isEmpty)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'No previous diagnoses found.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed crop analyses will be displayed here.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final rec = records[index];
                          final isHealthy = rec.result.healthStatus == 'EXCELLENT';
                          final Color statusColor = isHealthy ? AppTheme.primaryGreen : Colors.redAccent;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AppBar(
                                              title: Text(rec.result.crop, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              backgroundColor: AppTheme.primaryGreen,
                                              foregroundColor: Colors.white,
                                              automaticallyImplyLeading: false,
                                              elevation: 0,
                                              shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                              ),
                                              actions: [
                                                IconButton(
                                                  icon: const Icon(Icons.close_rounded),
                                                  onPressed: () => Navigator.pop(ctx),
                                                )
                                              ],
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                                              ),
                                              constraints: BoxConstraints(
                                                maxHeight: MediaQuery.of(context).size.height * 0.7,
                                              ),
                                              width: double.infinity,
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                                child: InteractiveViewer(
                                                  panEnabled: true,
                                                  boundaryMargin: const EdgeInsets.all(20),
                                                  minScale: 0.5,
                                                  maxScale: 4.0,
                                                  child: rec.imageBytes.isNotEmpty
                                                      ? Image.memory(rec.imageBytes, fit: BoxFit.contain)
                                                      : (rec.imageUrl != null && rec.imageUrl!.isNotEmpty
                                                          ? Image.network(rec.imageUrl!, fit: BoxFit.contain)
                                                          : const Icon(Icons.image_not_supported, size: 120, color: Colors.white)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: rec.imageBytes.isNotEmpty
                                        ? Image.memory(
                                            rec.imageBytes,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                          )
                                        : (rec.imageUrl != null && rec.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                rec.imageUrl!,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(
                                                  width: 64,
                                                  height: 64,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                                                ),
                                                loadingBuilder: (c, child, progress) {
                                                  if (progress == null) return child;
                                                  return Container(
                                                    width: 64,
                                                    height: 64,
                                                    color: Colors.grey[100],
                                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                  );
                                                },
                                              )
                                            : Container(
                                                width: 64,
                                                height: 64,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                                              )),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            rec.result.crop.toUpperCase(),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${rec.result.confidence.toStringAsFixed(1)}%',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        rec.result.diagnosis,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Scanned: ${rec.timestamp.hour.toString().padLeft(2, "0")}:${rec.timestamp.minute.toString().padLeft(2, "0")}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                          ),
                                          if (!rec.isSynced) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.sync_problem_rounded, size: 12, color: Colors.orange),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    _historyService.deleteRecord(rec);
                                    if (_historyService.records.isEmpty) {
                                      Navigator.of(context).pop();
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Scan record deleted.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();

    return Scaffold(
      appBar: AppBar(
        title: Text(trans.translate('scanner_title')),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: trans.translate('scan_history'),
            onPressed: _showHistoryBottomSheet,
          ),
          IconButton(
            icon: Icon(_showSettings ? Icons.settings_applications_rounded : Icons.settings_rounded),
            tooltip: trans.translate('scanner_settings'),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Indicator
                _buildStatusIndicator(),
                const SizedBox(height: 16),

                // Expandable API Settings Card
                if (_showSettings)
                  _buildSettingsPanel(),

                // Web specific warning banner
                if (kIsWeb)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.accentGold,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Chrome may open a file picker instead of the native camera depending on browser support.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Viewfinder / Preview block
                AspectRatio(
                  aspectRatio: 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_imageBytes != null)
                          kIsWeb
                              ? Image.memory(
                                  _imageBytes!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_imageFile!.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 56,
                                color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                trans.translate('no_image'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[650],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trans.translate('no_image_desc'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),

                        // Scanning Red Line Animation
                        if (_isAnalyzing)
                          Positioned.fill(
                            child: _buildScanningAnimation(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Photo Selection Controllers Grid
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(trans.translate('camera'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_library_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(trans.translate('gallery'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Analysis Execution Section
                if (_imageBytes != null && !_isAnalyzing)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _analyzeImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.analytics_rounded, size: 22, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  trans.translate('analyze'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: IconButton(
                          onPressed: _clearImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            ),
                          ),
                          icon: const Icon(Icons.delete_sweep_rounded),
                        ),
                      ),
                    ],
                  )
                else if (_imageBytes == null)
                  // Prompt Button to trigger SnackBar validation checking
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _analyzeImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[600],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            trans.translate('analyze'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loader during computation
                if (_isAnalyzing)
                  _buildAnalysisLoader(),

                // Diagnostic Result Presentation Cards
                if (_diagnosticResult != null && !_isAnalyzing)
                  _buildDiagnosisResultsCard(_diagnosticResult!),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    final trans = TranslationService();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_rounded, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                trans.translate('scanner_settings'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Switch Toggles
          const Text('Select AI Engine', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text(trans.translate('online_ai'))),
                  selected: _isOnlineMode,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isOnlineMode ? AppTheme.primaryGreen : Colors.black87,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isOnlineMode = true;
                        _diagnosticResult = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text(trans.translate('offline_ai'))),
                  selected: !_isOnlineMode,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_isOnlineMode ? AppTheme.primaryGreen : Colors.black87,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isOnlineMode = false;
                        _diagnosticResult = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // API Key field shown on Online mode
          if (_isOnlineMode) ...[
            if (_savedApiKey == null || _savedApiKey!.isEmpty)
              _buildSetupCard()
            else if (_isEditingApiKey)
              _buildEditCard()
            else
              _buildConnectedCard(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Offline AI (TFLite) is coming soon. Please use Online AI (Gemini) for instant leaf disease analysis.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[750], height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, value, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Stack(
            children: [
              Positioned(
                top: value * 240, // Height of preview is roughly 240
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisLoader() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: AppTheme.primaryGreen,
              strokeWidth: 3.5,
            ),
            const SizedBox(height: 16),
            Text(
              _isOnlineMode 
                  ? 'Transmitting base64 payload to Gemini Vision AI...' 
                  : 'Running TensorFlow Lite Model Inference...',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isOnlineMode 
                  ? 'Waiting for structured crop pathology JSON...' 
                  : 'Executing Interpreter.run on plant_disease_model.tflite...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisResultsCard(DiagnosticResult result) {
    final trans = TranslationService();
    final bool isHealthy = result.healthStatus == 'EXCELLENT';
    final Color statusColor = isHealthy 
        ? AppTheme.primaryGreen 
        : (result.healthStatus == 'WARNING' ? AppTheme.accentGold : Colors.redAccent);

    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Header Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${trans.translate('crop_label').toUpperCase()}: ${result.crop.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.healthStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Diagnostic Disease Title with TTS Speaker Replay Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  result.diagnosis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
                tooltip: 'Read diagnosis aloud',
                onPressed: () {
                  final String speakText = '${result.crop} - ${result.diagnosis}. '
                      '${result.symptoms.isNotEmpty ? "${trans.translate('symptoms_label')}: ${result.symptoms.join(". ")}" : ""}. '
                      '${result.remedies.isNotEmpty ? "${trans.translate('remedies_label')}: ${result.remedies.join(". ")}" : ""}';
                  TtsService.speak(speakText);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Calculated Confidence ratio
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: statusColor),
              const SizedBox(width: 6),
              Text(
                '${trans.translate('confidence_label')}: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[650],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${result.confidence.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // Horizontal scroll of Segmented Tab Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTabButton(0, Icons.info_outline_rounded, 'Symptoms', statusColor),
                const SizedBox(width: 8),
                _buildTabButton(1, Icons.eco_rounded, 'Organic Remedies', AppTheme.primaryGreen),
                const SizedBox(width: 8),
                _buildTabButton(2, Icons.science_rounded, 'Chemical Remedies', Colors.blueAccent),
                const SizedBox(width: 8),
                _buildTabButton(3, Icons.healing_rounded, 'Pesticides', Colors.purpleAccent),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Tab Panel Body
          _buildActiveTabBody(result, statusColor),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _activeResultTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeResultTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.15),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabBody(DiagnosticResult result, Color statusColor) {
    if (_activeResultTab == 0) {
      // Symptoms Tab
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Symptoms & Causes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          if (result.symptoms.isEmpty)
            Text('No specific symptoms reported.', style: TextStyle(color: Colors.grey[600], fontSize: 14))
          else
            ...result.symptoms.map((symptom) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.fiber_manual_record_rounded, size: 8, color: statusColor).margin(const EdgeInsets.only(top: 6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          symptom,
                          style: TextStyle(fontSize: 14, color: Colors.grey[750], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      );
    } else if (_activeResultTab == 1) {
      // Organic Remedies Tab
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Organic & Biological Remedies',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 10),
          if (result.organicRemedies.isEmpty)
            Text('No specific organic remedies listed. Maintain healthy leaf dryness and plant aeration.', style: TextStyle(color: Colors.grey[600], fontSize: 14))
          else
            ...result.organicRemedies.map((remedy) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remedy,
                          style: TextStyle(fontSize: 14, color: Colors.grey[750], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      );
    } else if (_activeResultTab == 2) {
      // Chemical Remedies Tab
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chemical & Standard Treatments',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          if (result.chemicalRemedies.isEmpty)
            Text('No chemical remedies recommended. Focus on biological management.', style: TextStyle(color: Colors.grey[600], fontSize: 14))
          else
            ...result.chemicalRemedies.map((remedy) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remedy,
                          style: TextStyle(fontSize: 14, color: Colors.grey[750], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      );
    } else {
      // Pesticides & Application Instructions Tab
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Pesticides',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
          ),
          const SizedBox(height: 8),
          if (result.suggestedPesticides.isEmpty)
            Text('No specific chemical/biological pesticides required.', style: TextStyle(color: Colors.grey[600], fontSize: 14))
          else
            ...result.suggestedPesticides.map((pesticide) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.colorize_rounded, size: 16, color: Colors.purpleAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pesticide,
                          style: TextStyle(fontSize: 14, color: Colors.grey[750], height: 1.4, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 18),
          const Text(
            'Application & Safety Instructions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
          ),
          const SizedBox(height: 8),
          if (result.applicationInstructions.isEmpty)
            Text('Wear protective gloves, spray during dry mornings or calm evenings.', style: TextStyle(color: Colors.grey[600], fontSize: 14))
          else
            ...result.applicationInstructions.map((instruction) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instruction,
                          style: TextStyle(fontSize: 14, color: Colors.grey[750], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      );
    }
  }
}

// Simple helper widget to provide margins to icons
extension IconExtension on Icon {
  Widget margin(EdgeInsetsGeometry margin) {
    return Padding(
      padding: margin,
      child: this,
    );
  }
}
