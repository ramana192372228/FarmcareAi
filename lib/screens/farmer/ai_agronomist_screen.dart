import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../theme/app_theme.dart';
import '../../services/gemini_service.dart';
import '../../services/translation_service.dart';
import '../../services/tts_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiAgronomistScreen extends StatefulWidget {
  const AiAgronomistScreen({super.key});

  @override
  State<AiAgronomistScreen> createState() => _AiAgronomistScreenState();
}

class _AiAgronomistScreenState extends State<AiAgronomistScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  bool _showApiKey = false;
  String _userId = 'anonymous';

  final List<_ChatMessage> _messages = [];

  static const List<String> _suggestedQuestions = [
    'Why are my cotton leaves turning yellow?',
    'When should I spray pesticide after rain?',
    'How much fertilizer should I apply for tomato?',
    'My rice crop has brown spots — what disease is it?',
    'What is the best time to irrigate wheat crop?',
    'How do I control bollworm in cotton organically?',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSavedApiKey();
    _loadUserAndHistory();
  }

  Future<void> _loadUserAndHistory() async {
    final phone = await AuthService().getLoggedUserPhone();
    final uid = phone ?? 'anonymous';
    if (mounted) {
      setState(() => _userId = uid);
    }

    FirestoreService().getAiChatHistoryStream(uid).listen((history) {
      if (!mounted) return;
      if (history.isNotEmpty) {
        setState(() {
          _messages.clear();
          for (final doc in history) {
            _messages.add(_ChatMessage(
              text: doc['text'] as String? ?? '',
              isBot: doc['isBot'] as bool? ?? false,
              isError: doc['isError'] as bool? ?? false,
            ));
          }
        });
        _scrollToBottom();
      } else if (_messages.isEmpty) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Namaste! I am your AI Agronomy Expert. Ask me anything about crops, pests, diseases, fertilizers, or farming practices. You can type or use voice input.',
            isBot: true,
          ));
        });
      }
    });
  }

  void _loadSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      if (mounted) {
        setState(() {
          _apiKeyController.text = savedKey;
        });
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    if (_isListening) _speech?.stop();
    TtsService.stop();
    super.dispose();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleListening() async {
    try {
      _speech ??= stt.SpeechToText();
      
      if (_isListening) {
        await _speech!.stop();
        setState(() => _isListening = false);
        return;
      }

      final lang = TranslationService().currentLanguage;
      final Map<AppLanguage, String> localeMap = {
        AppLanguage.telugu: 'te-IN',
        AppLanguage.tamil: 'ta-IN',
        AppLanguage.hindi: 'hi-IN',
        AppLanguage.kannada: 'kn-IN',
        AppLanguage.malayalam: 'ml-IN',
      };
      
      final String localeId = localeMap[lang] ?? 'en-US';

      bool available = await _speech!.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Voice error: ${e.errorMsg}')),
            );
          }
        },
      );

      if (available) {
        setState(() => _isListening = true);
        await _speech!.listen(
          onResult: (result) {
            if (mounted && result.finalResult) {
              _questionController.text = result.recognizedWords;
              setState(() => _isListening = false);
            }
          },
          listenOptions: stt.SpeechListenOptions(localeId: localeId),
        );
      }
    } catch (e) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty) return;
    if (_isListening) {
      await _speech?.stop();
      setState(() => _isListening = false);
    }

    final q = question.trim();
    _questionController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: q, isBot: false));
      _isLoading = true;
    });
    _scrollToBottom();

    // Save user question to Firestore
    FirestoreService().saveAiChatMessage(_userId, q, false);

    final lang = TranslationService().currentLanguage;
    String langName = 'English';
    switch (lang) {
      case AppLanguage.telugu: langName = 'Telugu'; break;
      case AppLanguage.tamil: langName = 'Tamil'; break;
      case AppLanguage.hindi: langName = 'Hindi'; break;
      case AppLanguage.kannada: langName = 'Kannada'; break;
      case AppLanguage.malayalam: langName = 'Malayalam'; break;
      default: langName = 'English';
    }

    try {
      final response = await GeminiService.askAgronomist(
        question: q,
        customApiKey: _apiKeyController.text.trim(),
        languageName: langName,
      );
      setState(() {
        _messages.add(_ChatMessage(text: response, isBot: true));
        _isLoading = false;
      });
      // Save AI bot response to Firestore
      FirestoreService().saveAiChatMessage(_userId, response, true);
    } catch (e) {
      const errText = 'Unable to connect to the AI Expert. Please check your API key in settings, or try again.';
      setState(() {
        _messages.add(_ChatMessage(
          text: errText,
          isBot: true,
          isError: true,
        ));
        _isLoading = false;
      });
      FirestoreService().saveAiChatMessage(_userId, errText, true, isError: true);
    }
    _scrollToBottom();
  }

  Future<void> _speakMessage(String text) async {
    if (_isSpeaking) {
      await TtsService.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await TtsService.speak(text);
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Column(
          children: [
            Text('AI Agronomist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Powered by Gemini AI', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear Chat History',
            onPressed: () async {
              await FirestoreService().clearAiChatHistory(_userId);
              if (mounted) {
                setState(() {
                  _messages.clear();
                  _messages.add(_ChatMessage(
                    text: 'Chat history cleared. How can I help you with your farm today?',
                    isBot: true,
                  ));
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'API Key',
            onPressed: () => setState(() => _showApiKey = !_showApiKey),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // API Key panel (toggleable)
            if (_showApiKey)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter Gemini API Key',
                    prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.primaryGreen, size: 18),
                    suffixIcon: IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _showApiKey = false)),
                    filled: true, fillColor: AppTheme.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),

            // Suggested questions (shown only when chat is empty / just greeting)
            if (_messages.length == 1)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Suggested Questions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedQuestions.map((q) => GestureDetector(
                        onTap: () => _sendQuestion(q),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.18)),
                          ),
                          child: Text(q, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (_isLoading && i == _messages.length) {
                    return _typingBubble();
                  }
                  return _messageBubble(_messages[i]);
                },
              ),
            ),

            // Input row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Row(
                children: [
                  // Mic button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.redAccent.withValues(alpha: 0.12) : AppTheme.primaryGreen.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.redAccent : AppTheme.primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                      child: TextField(
                        controller: _questionController,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendQuestion,
                        decoration: const InputDecoration(
                          hintText: 'Ask your farming question...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Send button
                  GestureDetector(
                    onTap: () => _sendQuestion(_questionController.text),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryGreen,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(_ChatMessage msg) {
    final isBot = msg.isBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isBot
                    ? (msg.isError ? Colors.redAccent.withValues(alpha: 0.08) : Colors.white)
                    : AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isBot ? 4 : 18),
                  bottomRight: Radius.circular(isBot ? 18 : 4),
                ),
                border: isBot ? Border.all(color: msg.isError ? Colors.redAccent.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.12)) : null,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isBot ? Colors.black87 : Colors.white,
                      height: 1.45,
                    ),
                  ),
                  if (isBot && !msg.isError) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _speakMessage(msg.text),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded, size: 15, color: AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          Text(_isSpeaking ? 'Stop' : 'Listen', style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: AppTheme.primaryGreen, size: 17),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 150),
                SizedBox(width: 4),
                _TypingDot(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  final bool isError;
  _ChatMessage({required this.text, required this.isBot, this.isError = false});
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGreen),
      ),
    );
  }
}
