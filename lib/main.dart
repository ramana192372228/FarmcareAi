import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[FIREBASE_INIT] Firebase successfully initialized.');
  } catch (e) {
    debugPrint('[FIREBASE_INIT] Error initializing Firebase: $e');
  }
  runApp(const FarmCareAIApp());
}

class FarmCareAIApp extends StatelessWidget {
  const FarmCareAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranslationService(),
      builder: (context, child) {
        return MaterialApp(
          title: 'FarmCare AI',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}

