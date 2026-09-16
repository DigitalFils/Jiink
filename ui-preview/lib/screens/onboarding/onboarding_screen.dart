import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.verified_user_rounded,
      title: 'Authenticity Guaranteed',
      description: 'Every item verified by our expert team. Dewu-grade authentication with detailed certificates and 10x money-back guarantee.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.accent.withOpacity(0.2), AppTheme.accentDark.withOpacity(0.05)],
      ),
    ),
    OnboardingPage(
      icon: Icons.live_tv_rounded,
      title: 'Live Shopping Experience',
      description: 'Watch sellers showcase products in real-time. Ask questions, get exclusive deals, and shop interactively like never before.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.liveRed.withOpacity(0.2), AppTheme.accent.withOpacity(0.05)],
      ),
    ),
    OnboardingPage(
      icon: Icons.groups_rounded,
      title: 'Smart Group Buying',
      description: 'Team up with other buyers for unbeatable prices. Real-time tracking, instant notifications, and PDD-style savings.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.info.withOpacity(0.2), AppTheme.accent.withOpacity(0.05)],
      ),
    ),
    OnboardingPage(
      icon: Icons.view_in_ar_rounded,
      title: 'AR Virtual Try-On',
      description: 'See how sneakers, clothing, and accessories look on you before buying. Revolutionary AR technology built right in.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.gold.withOpacity(0.2), AppTheme.accent.withOpacity(0.05)],
      ),
    ),
    OnboardingPage(
      icon: Icons.map_rounded,
      title: 'Local & Global',
      description: 'Find hidden gems nearby or shop from sellers worldwide. Avito-style local discovery with global marketplace reach.',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.success.withOpacity(0.2), AppTheme.accent.withOpacity(0.05)],
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'S8LL',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accent,
                      letterSpacing: -1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _completeOnboarding(),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: AppAnimations.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppTheme.accent : AppTheme.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: AppAnimations.medium,
                            curve: AppAnimations.easeOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Continue' : 'Get Started',
                        style: const TextStyle(fontSize: 18),
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

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AppAnimations.slow,
            curve: AppAnimations.bounce,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: page.gradient,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: AppTheme.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    page.icon,
                    color: AppTheme.accent,
                    size: 72,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacementNamed('/main');
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
