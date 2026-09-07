import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/app_animations.dart';

/// v2's onboarding, carried over as designed: five pages, the same icons,
/// the same tinted gradient tiles bouncing in, the same expanding dots and
/// Continue → Get Started button.
///
/// The words are the one thing that changed, and only where the prototype
/// promised something nothing behind it can do. It offered "every item
/// verified by our expert team", "Dewu-grade authentication with detailed
/// certificates" and a "10x money-back guarantee". There is no
/// authentication team, no certificate, and no such guarantee — and a
/// money-back guarantee is a consumer promise, not a strapline, so it
/// can't ship as decoration. Each page now says the true version of the
/// same idea. Restore any of them the moment the thing behind it exists.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.verified_user_rounded,
      title: 'Paid for safely',
      // Was: "Every item verified by our expert team… 10x money-back
      // guarantee." This is what actually protects a buyer here.
      description:
          'Card payments run through Stripe, so your details never touch us. '
          'Every seller is a real account with a rating you can read before '
          'you buy.',
      tint: S8llColors.lime,
    ),
    _OnboardingPage(
      icon: Icons.local_fire_department_rounded,
      title: 'Live for eight hours',
      description:
          'Every listing is a drop. It goes up, it runs for eight hours, and '
          'then it is gone unless the seller puts it back. No dead adverts '
          'from last March.',
      tint: S8llColors.live,
    ),
    _OnboardingPage(
      icon: Icons.sell_rounded,
      title: 'Make an offer',
      description:
          'Not sold on the price? Send the seller an offer in one tap. If '
          'they accept it, that is the price you pay at checkout.',
      tint: S8llColors.info,
    ),
    _OnboardingPage(
      icon: Icons.photo_camera_rounded,
      title: 'Snap it, sell it',
      description:
          'Photograph the thing, name it, price it. One screen, no wizard — '
          'it is live before you have put your phone down.',
      tint: S8llColors.gold,
    ),
    _OnboardingPage(
      icon: Icons.map_rounded,
      title: 'Sold near you',
      description:
          'Meet up in town or have it shipped. Every listing says which, and '
          'which city it is coming from, before you commit to anything.',
      tint: S8llColors.success,
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
      backgroundColor: S8llColors.black,
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
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: S8llColors.lime,
                      letterSpacing: -1,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onDone,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: S8llColors.grey,
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
                itemBuilder: (context, index) => _Page(page: _pages[index]),
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
                          color: _currentPage == index ? S8llColors.lime : S8llColors.divider,
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
                          widget.onDone();
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
}

class _Page extends StatelessWidget {
  const _Page({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AppAnimations.slow,
            curve: AppAnimations.bounce,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      page.tint.withValues(alpha: 0.2),
                      S8llColors.limeDim.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: S8llColors.lime.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(page.icon, color: S8llColors.lime, size: 72),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: S8llColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: S8llColors.grey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String description;

  /// The first stop of the page's gradient tile — v2 varied this per page
  /// (lime, live red, info blue, gold, success green) and so does this.
  final Color tint;
}
