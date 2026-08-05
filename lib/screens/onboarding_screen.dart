import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import 'role_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPageData> get _pages {
    final trans = TranslationService();
    return [
      OnboardingPageData(
        title: trans.translate('onboarding_title_1'),
        description: trans.translate('onboarding_desc_1'),
        icon: Icons.camera_enhance_rounded,
        accentColor: AppTheme.primaryGreen,
        bgCircleColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
      ),
      OnboardingPageData(
        title: trans.translate('onboarding_title_2'),
        description: trans.translate('onboarding_desc_2'),
        icon: Icons.storefront_rounded,
        accentColor: AppTheme.accentGold,
        bgCircleColor: AppTheme.accentGold.withValues(alpha: 0.08),
      ),
      OnboardingPageData(
        title: trans.translate('onboarding_title_3'),
        description: trans.translate('onboarding_desc_3'),
        icon: Icons.wb_sunny_rounded,
        accentColor: AppTheme.secondaryGreen,
        bgCircleColor: AppTheme.secondaryGreen.withValues(alpha: 0.12),
      ),
    ];
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RoleScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trans = TranslationService();
    final pagesList = _pages;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    trans.translate('skip'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            
            // Onboarding Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pagesList.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = pagesList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated graphic illustration container
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: page.bgCircleColor,
                              ),
                            ),
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: page.accentColor.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                page.icon,
                                size: 84,
                                color: page.accentColor,
                              ),
                            ),
                            // Micro agricultural decorative particles
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Icon(Icons.eco_rounded, size: 24, color: AppTheme.secondaryGreen.withValues(alpha: 0.4)),
                            ),
                            Positioned(
                              bottom: 30,
                              left: 10,
                              child: Icon(Icons.water_drop_rounded, size: 20, color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            Positioned(
                              bottom: 40,
                              right: 25,
                              child: Icon(Icons.filter_hdr_rounded, size: 22, color: AppTheme.accentGold.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        
                        // Slide Title
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Slide Description
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Controller Layout
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0, left: 32.0, right: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      pagesList.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next / Done button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage == pagesList.length - 1) {
                        _navigateToLogin();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentPage == pagesList.length - 1
                            ? Icons.done_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
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
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color bgCircleColor;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.bgCircleColor,
  });
}
