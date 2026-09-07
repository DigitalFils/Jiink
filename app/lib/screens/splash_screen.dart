import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/app_animations.dart';

/// The v2 splash, carried over as designed: the lime tile bouncing up under
/// its own glow, then the wordmark and strapline sliding in behind it.
///
/// The only change from the prototype is where it goes next. There it
/// pushed a named route on a timer; here it calls [onDone], because what
/// follows depends on whether this person has seen the onboarding and
/// whether they're signed in — decisions the app makes, not the splash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;
  Timer? _handoff;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppAnimations.verySlow);

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: AppAnimations.bounce),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: AppAnimations.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: AppAnimations.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: AppAnimations.easeOut),
      ),
    );

    _controller.forward();
    // Cancelled in dispose: the prototype's bare Timer called Navigator on
    // a screen that may already be gone if anything moved on first.
    _handoff = Timer(const Duration(milliseconds: 2500), widget.onDone);
  }

  @override
  void dispose() {
    _handoff?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: S8llColors.black,
      body: Container(
        decoration: const BoxDecoration(gradient: S8llGradients.dark),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: S8llColors.lime,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: S8llColors.lime.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: S8llColors.black,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _textOpacity.value,
                  child: SlideTransition(
                    position: _textSlide,
                    child: const Text(
                      'S8LL',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: S8llColors.lime,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _textOpacity.value * 0.7,
                  child: SlideTransition(
                    position: _textSlide,
                    child: const Text(
                      'Marketplace Reimagined',
                      style: TextStyle(
                        fontSize: 16,
                        color: S8llColors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
