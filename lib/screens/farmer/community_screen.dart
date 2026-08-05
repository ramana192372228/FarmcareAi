import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../services/translation_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Live local Q&A feed list
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _userId;
  String? _userName;
  String? _userRole;

  final _questionController = TextEditingController();
  final _commentController = TextEditingController();

  final Map<AppLanguage, Map<String, String>> _localizedComm = {
    AppLanguage.english: {
      'ask_btn': 'Ask Advisory Forum',
      'ask_header': 'Ask Agricultural Experts',
      'hint_question': 'Write your farming question here...',
      'submit_btn': 'Post Question',
      'expert_badge': 'Verified Expert',
      'answers_title': 'Discussion Thread',
      'add_reply': 'Write an answer...',
      'send_btn': 'Reply',
      'likes': 'Likes',
    },
    AppLanguage.telugu: {
      'ask_btn': 'వ్యవసాయ నిపుణులను అడగండి',
      'ask_header': 'వ్యవసాయ ప్రశ్నను అడగండి',
      'hint_question': 'మీ వ్యవసాయ ప్రశ్నను ఇక్కడ రాయండి...',
      'submit_btn': 'పోస్ట్ చేయి',
      'expert_badge': 'ధృవీకరించబడిన నిపుణుడు',
      'answers_title': 'చర్చా వేదిక',
      'add_reply': 'సమాధానం రాయండి...',
      'send_btn': 'సమాధానం ఇవ్వు',
      'likes': 'లైకులు',
    },
    AppLanguage.tamil: {
      'ask_btn': 'மன்றத்தில் கேள்வியெழுப்பு',
      'ask_header': 'விவசாய நிபுணர்களிடம் கேளுங்கள்',
      'hint_question': 'உங்கள் விவசாயக் கேள்வியை இங்கே எழுதுங்கள்...',
      'submit_btn': 'கேள்வியெழும்பவும்',
      'expert_badge': 'சான்றளிக்கப்பட்ட நிபுணர்',
      'answers_title': 'விவாத அரங்கு',
      'add_reply': 'பதில் எழுதுங்கள்...',
      'send_btn': 'பதில் அளி',
      'likes': 'விருப்பங்கள்',
    },
    AppLanguage.hindi: {
      'ask_btn': 'सलाहकार मंच से पूछें',
      'ask_header': 'कृषि विशेषज्ञों से पूछें',
      'hint_question': 'अपनी खेती से संबंधित प्रश्न यहाँ लिखें...',
      'submit_btn': 'प्रश्न पोस्ट करें',
      'expert_badge': 'प्रमाणित विशेषज्ञ',
      'answers_title': 'चर्चा मंच',
      'add_reply': 'अपना उत्तर लिखें...',
      'send_btn': 'उत्तर दें',
      'likes': 'पसंद',
    },
    AppLanguage.kannada: {
      'ask_btn': 'ಸಲಹಾ ವೇದಿಕೆಯಲ್ಲಿ ಕೇಳಿ',
      'ask_header': 'ಕೃಷಿ ತಜ್ಞರನ್ನು ಪ್ರಶ್ನಿಸಿ',
      'hint_question': 'ನಿಮ್ಮ ಕೃಷಿ ಪ್ರಶ್ನೆಯನ್ನು ಇಲ್ಲಿ ಬರೆಯಿರಿ...',
      'submit_btn': 'ಪ್ರಶ್ನೆ ಸಲ್ಲಿಸಿ',
      'expert_badge': 'ಪ್ರಮಾಣೀಕೃತ ತಜ್ಞರು',
      'answers_title': 'ಚರ್ಚಾ ವೇದಿಕೆ',
      'add_reply': 'ಉತ್ತರವನ್ನು ಬರೆಯಿರಿ...',
      'send_btn': 'ಪ್ರತ್ಯುತ್ತರಿಸಿ',
      'likes': 'ಲೈಕ್\u200cಗಳು',
    },
    AppLanguage.malayalam: {
      'ask_btn': 'കൂട്ടായ്മയിൽ ചോദിക്കുക',
      'ask_header': 'കൃഷി വിദഗ്ദ്ധരോട് ചോദിക്കാം',
      'hint_question': 'നിങ്ങളുടെ സംശയങ്ങൾ ഇവിടെ എഴുതുക...',
      'submit_btn': 'ചോദ്യം പോസ്റ്റ് ചെയ്യുക',
      'expert_badge': 'സാക്ഷ്യപ്പെടുത്തിയ വിദഗ്ദ്ധൻ',
      'answers_title': 'ചർച്ചാ വേദി',
      'add_reply': 'മറുപടി എഴുതുക...',
      'send_btn': 'മറുപടി നൽകുക',
      'likes': 'ഇഷ്ടങ്ങൾ',
    },
  };

  String _getText(String key) {
    final lang = TranslationService().currentLanguage;
    final map = _localizedComm[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return _localizedComm[AppLanguage.english]![key]!;
  }

  stt.SpeechToText? _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final auth = AuthService();
    _userId = await auth.getLoggedUserPhone();
    if (_userId != null) {
      final profile = await auth.getUserProfile(_userId!);
      if (profile != null) {
        _userName = profile.name;
        _userRole = profile.role == 'farmer' ? '${profile.district ?? ""} Farmer' : 'Shop Owner';
      }
    }

    bool loadedFromFirestore = false;
    try {
      debugPrint('[COMMUNITY_SCREEN] Loading posts from Firestore first...');
      final posts = await FirestoreService().getCommunityPosts();
      if (posts.isNotEmpty) {
        setState(() {
          _posts = posts;
        });
        loadedFromFirestore = true;
        
        // Save/Sync to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final serializablePosts = posts.map((item) {
          final copy = Map<String, dynamic>.from(item);
          if (copy['createdAt'] is Timestamp) {
            copy['createdAt'] = (copy['createdAt'] as Timestamp).millisecondsSinceEpoch;
          }
          if (copy['replies'] is List) {
            copy['replies'] = (copy['replies'] as List).map((r) {
              final rCopy = Map<String, dynamic>.from(r as Map);
              if (rCopy['createdAt'] is Timestamp) {
                rCopy['createdAt'] = (rCopy['createdAt'] as Timestamp).millisecondsSinceEpoch;
              }
              return rCopy;
            }).toList();
          }
          return copy;
        }).toList();
        await prefs.setString('community_posts_cache', jsonEncode(serializablePosts));
        debugPrint('[COMMUNITY_SCREEN] Loaded ${posts.length} posts from Firestore.');
      }
    } catch (e) {
      debugPrint('[COMMUNITY_SCREEN] Error loading posts from Firestore: $e');
    }

    if (!loadedFromFirestore) {
      debugPrint('[COMMUNITY_SCREEN] Falling back to SharedPreferences/Mock posts.');
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('community_posts_cache');
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as List;
          setState(() {
            _posts = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          });
        } catch (e) {
          debugPrint('[COMMUNITY_SCREEN] Error decoding cached posts: $e');
        }
      } else {
        // If no cache, use default fallback hardcoded posts
        setState(() {
          _posts = [
            {
              'postId': 'post_seed_1',
              'farmer': 'Nayak',
              'role': 'Cotton Cultivator',
              'question': 'How can I organically treat early-stage whitefly infestation in cotton?',
              'replies': [
                {'name': 'Dr. Sharma (Agronomist)', 'text': 'Spray organic Neem Oil (1500ppm) mixed with soap solution in early mornings. Repeat every 5 days.', 'verified': true},
                {'name': 'Ramesh Kumar', 'text': 'Also install yellow sticky traps across the fields, it works wonders!', 'verified': false},
              ],
              'likes': 14,
              'replyCount': 2,
              'createdAt': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
              'language': 'English',
              'userId': 'seed_nayak',
              'userName': 'Nayak',
            },
            {
              'postId': 'post_seed_2',
              'farmer': 'Anjali',
              'role': 'Tomato Farmer',
              'question': 'Leaves are curling upwards with yellow spots. Is this mosaic virus or nutrient deficiency?',
              'replies': [
                {'name': 'Dr. Sharma (Agronomist)', 'text': 'Curl leaves with yellow patches point heavily to Tomato Yellow Leaf Curl Virus spread by whiteflies. Isolate infected plants.', 'verified': true},
              ],
              'likes': 8,
              'replyCount': 1,
              'createdAt': DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
              'language': 'English',
              'userId': 'seed_anjali',
              'userName': 'Anjali',
            },
          ];
        });
      }
    }

    setState(() => _isLoading = false);
  }

  void _initSpeech() async {
    try {
      _speech = stt.SpeechToText();
    } catch (e) {
      debugPrint('[COMMUNITY_SPEECH] SpeechToText initialisation error: $e');
    }
  }

  void _toggleListening(StateSetter setSheetState) async {
    _speech ??= stt.SpeechToText();

    final trans = TranslationService();

    if (_isListening) {
      try {
        await _speech!.stop();
      } catch (_) {}
      setSheetState(() {
        _isListening = false;
      });
      setState(() {});
    } else {
      try {
        bool available = await _speech!.initialize(
          onStatus: (status) {
            debugPrint('[COMMUNITY_SPEECH] Speech status: $status');
            if (status == 'done' || status == 'notListening') {
              if (mounted) {
                setSheetState(() {
                  _isListening = false;
                });
                setState(() {});
              }
            }
          },
          onError: (errorNotification) {
            debugPrint('[COMMUNITY_SPEECH] Speech error: $errorNotification');
            if (mounted) {
              setSheetState(() {
                _isListening = false;
              });
              setState(() {});
            }
          },
        );

        if (available) {
          final lang = TranslationService().currentLanguage;
          String localeId = 'en-US';
          switch (lang) {
            case AppLanguage.telugu:
              localeId = 'te-IN';
              break;
            case AppLanguage.tamil:
              localeId = 'ta-IN';
              break;
            case AppLanguage.hindi:
              localeId = 'hi-IN';
              break;
            case AppLanguage.kannada:
              localeId = 'kn-IN';
              break;
            case AppLanguage.malayalam:
              localeId = 'ml-IN';
              break;
            default:
              localeId = 'en-US';
          }

          setSheetState(() {
            _isListening = true;
          });
          setState(() {});

          await _speech!.listen(
            onResult: (result) {
              if (mounted) {
                setSheetState(() {
                  _questionController.text = result.recognizedWords;
                });
              }
            },
            listenOptions: stt.SpeechListenOptions(
              localeId: localeId,
            ),
          );
        } else {
          _showToast(trans.translate('speech_unavailable'));
        }
      } catch (e) {
        debugPrint('[COMMUNITY_SPEECH] Speech initialization error: $e');
        _showToast(trans.translate('speech_unavailable'));
      }
    }
  }

  void _showToast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_speech != null && _isListening) {
      _speech!.stop();
    }
    _questionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postNewQuestion() async {
    if (_questionController.text.trim().isEmpty) return;

    final String qText = _questionController.text.trim();
    final String pId = 'post_${DateTime.now().millisecondsSinceEpoch}';
    final String currentLangStr = TranslationService().currentLanguage.name;

    final Map<String, dynamic> postData = {
      'postId': pId,
      'userId': _userId ?? 'anonymous',
      'userName': _userName ?? 'You',
      'farmer': _userName ?? 'You',
      'role': _userRole ?? 'Progressive Farmer',
      'question': qText,
      'createdAt': Timestamp.now(),
      'language': currentLangStr,
      'likes': 0,
      'replyCount': 0,
      'replies': [],
    };

    // 1. Write to Firestore first
    try {
      await FirestoreService().saveCommunityPost(pId, postData);
    } catch (e) {
      debugPrint('[COMMUNITY_SCREEN] Firestore post save error: $e');
    }

    // Update local state
    setState(() {
      _posts.insert(0, postData);
    });

    // 2. Save SharedPreferences fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializablePosts = _posts.map((p) {
        final copy = Map<String, dynamic>.from(p);
        if (copy['createdAt'] is Timestamp) {
          copy['createdAt'] = (copy['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        if (copy['replies'] is List) {
          copy['replies'] = (copy['replies'] as List).map((r) {
            final rCopy = Map<String, dynamic>.from(r as Map);
            if (rCopy['createdAt'] is Timestamp) {
              rCopy['createdAt'] = (rCopy['createdAt'] as Timestamp).millisecondsSinceEpoch;
            }
            return rCopy;
          }).toList();
        }
        return copy;
      }).toList();
      await prefs.setString('community_posts_cache', jsonEncode(serializablePosts));
    } catch (e) {
      debugPrint('[COMMUNITY_SCREEN] SharedPreferences post save error: $e');
    }

    if (!mounted) return;
    _questionController.clear();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your question has been broadcast to agricultural experts!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
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
                  child: Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 24),
                Text(_getText('ask_header'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const SizedBox(height: 16),
                TextField(
                  controller: _questionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _getText('hint_question'),
                    filled: true,
                    fillColor: AppTheme.backgroundLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Voice posting micro-interaction
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.redAccent.withValues(alpha: 0.12)
                            : AppTheme.primaryGreen.withValues(alpha: 0.08),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _isListening ? Colors.redAccent : AppTheme.primaryGreen,
                          size: 24,
                        ),
                        onPressed: () => _toggleListening(setSheetState),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isListening
                                ? TranslationService().translate('speech_listening')
                                : TranslationService().translate('speech_tap_to_record'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isListening ? Colors.redAccent : AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Supports Telugu, Tamil, Hindi, Kannada, Malayalam & English',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _postNewQuestion,
                    child: Text(_getText('submit_btn'), style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showRepliesSheet(int index) {
    final post = _posts[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        bool repliesLoading = true;
        List repliesList = post['replies'] ?? [];

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (repliesLoading) {
              FirestoreService().getCommunityReplies(post['postId'] ?? '').then((fetched) {
                if (context.mounted) {
                  setModalState(() {
                    repliesList = fetched;
                    post['replies'] = fetched;
                    repliesLoading = false;
                  });
                }
              }).catchError((e) {
                debugPrint('[COMMUNITY_SCREEN] Error loading replies: $e');
                if (context.mounted) {
                  setModalState(() {
                    repliesLoading = false;
                  });
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Text(_getText('answers_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    const Divider(height: 24),
                    Expanded(
                      child: repliesLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                          : repliesList.isEmpty
                              ? const Center(child: Text('No answers yet. Be the first to answer!', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  controller: scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: repliesList.length,
                                  itemBuilder: (context, rIndex) {
                                    final rep = repliesList[rIndex];
                                    final isExp = rep['verified'] == true;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isExp ? AppTheme.primaryGreen.withValues(alpha: 0.05) : AppTheme.backgroundLight,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isExp ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.transparent),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(rep['name'] ?? rep['userName'] ?? 'Farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                              const SizedBox(width: 8),
                                              if (isExp)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(4)),
                                                  child: Text(_getText('expert_badge'), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(rep['text'] ?? rep['message'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[750], height: 1.4)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: _getText('add_reply'),
                              filled: true,
                              fillColor: AppTheme.backgroundLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_commentController.text.trim().isEmpty) return;
                              final replyText = _commentController.text.trim();
                              final String replyName = _userName != null ? '$_userName (Farmer)' : 'You (Farmer)';
                              final String rId = 'reply_${DateTime.now().millisecondsSinceEpoch}';

                              final replyMap = {
                                'replyId': rId,
                                'userId': _userId ?? 'anonymous',
                                'userName': _userName ?? 'You',
                                'name': replyName,
                                'message': replyText,
                                'text': replyText,
                                'createdAt': Timestamp.now(),
                                'verified': false,
                              };

                              final String postId = post['postId'] ?? '';
                              if (postId.isNotEmpty) {
                                try {
                                  // 1. Save reply under community_posts/{postId}/replies/{replyId}
                                  await FirestoreService().saveCommunityReply(postId, rId, replyMap);

                                  // 2. Increment parent post's replyCount in Firestore
                                  final newReplyCount = (post['replyCount'] as int? ?? 0) + 1;
                                  await FirestoreService().saveCommunityPost(postId, {
                                    'replyCount': newReplyCount,
                                  });
                                } catch (e) {
                                  debugPrint('[COMMUNITY_SCREEN] Firestore reply save error: $e');
                                }
                              }

                              // Update local UI state
                              setState(() {
                                post['replies'] ??= [];
                                post['replies'].add(replyMap);
                                post['replyCount'] = post['replies'].length;
                                // Sync repliesList reference
                                repliesList = post['replies'];
                              });

                              // Save SharedPreferences fallback
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final serializablePosts = _posts.map((p) {
                                  final copy = Map<String, dynamic>.from(p);
                                  if (copy['createdAt'] is Timestamp) {
                                    copy['createdAt'] = (copy['createdAt'] as Timestamp).millisecondsSinceEpoch;
                                  }
                                  if (copy['replies'] is List) {
                                    copy['replies'] = (copy['replies'] as List).map((r) {
                                      final rCopy = Map<String, dynamic>.from(r as Map);
                                      if (rCopy['createdAt'] is Timestamp) {
                                        rCopy['createdAt'] = (rCopy['createdAt'] as Timestamp).millisecondsSinceEpoch;
                                      }
                                      return rCopy;
                                    }).toList();
                                  }
                                  return copy;
                                }).toList();
                                await prefs.setString('community_posts_cache', jsonEncode(serializablePosts));
                              } catch (e) {
                                debugPrint('[COMMUNITY_SCREEN] SharedPreferences reply save error: $e');
                              }

                              setModalState(() {
                                _commentController.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_getText('send_btn'), style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(trans.translate('community')),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : Column(
                children: [
            // Top Advisory Form Trigger Card
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _showAskDialog,
                  icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
                  label: Text(_getText('ask_btn'), style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),

            // Live Forum Q&A List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final replies = post['replies'] as List? ?? [];
                  final hasExpert = replies.any((element) => element['verified'] == true);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Roster Header Info
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.08), shape: BoxShape.circle),
                              child: const Icon(Icons.person_rounded, color: AppTheme.primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['farmer'] ?? post['userName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(post['role'] ?? 'Progressive Farmer', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // The Question
                        Text(
                          post['question']!,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.4),
                        ),
                        const Divider(height: 28),

                        // Footer Panel actions
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                setState(() {
                                  post['likes'] = (post['likes'] as int? ?? 0) + 1;
                                });

                                // Write to Firestore first
                                final String postId = post['postId'] ?? '';
                                if (postId.isNotEmpty) {
                                  try {
                                    await FirestoreService().saveCommunityPost(postId, {
                                      'likes': post['likes'],
                                    });
                                  } catch (e) {
                                    debugPrint('[COMMUNITY_SCREEN] Firestore like save error: $e');
                                  }
                                }

                                // Save SharedPreferences fallback
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final serializablePosts = _posts.map((p) {
                                    final copy = Map<String, dynamic>.from(p);
                                    if (copy['createdAt'] is Timestamp) {
                                      copy['createdAt'] = (copy['createdAt'] as Timestamp).millisecondsSinceEpoch;
                                    }
                                    if (copy['replies'] is List) {
                                      copy['replies'] = (copy['replies'] as List).map((r) {
                                        final rCopy = Map<String, dynamic>.from(r as Map);
                                        if (rCopy['createdAt'] is Timestamp) {
                                          rCopy['createdAt'] = (rCopy['createdAt'] as Timestamp).millisecondsSinceEpoch;
                                        }
                                        return rCopy;
                                      }).toList();
                                    }
                                    return copy;
                                  }).toList();
                                  await prefs.setString('community_posts_cache', jsonEncode(serializablePosts));
                                } catch (e) {
                                  debugPrint('[COMMUNITY_SCREEN] SharedPreferences like save error: $e');
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('${post['likes']} ${_getText('likes')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () => _showRepliesSheet(index),
                              child: Row(
                                children: [
                                  Icon(Icons.forum_outlined, size: 18, color: hasExpert ? AppTheme.primaryGreen : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${post['replyCount'] ?? replies.length} Answers',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: hasExpert ? FontWeight.bold : FontWeight.normal,
                                      color: hasExpert ? AppTheme.primaryGreen : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
