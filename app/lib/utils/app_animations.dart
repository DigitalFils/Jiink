import 'package:flutter/material.dart';

/// S8LL v2.0 — Standardized Motion System
///
/// Single source of truth for every duration, curve and page transition
/// in the app. All screens route their animations through [AppMotion]
/// so the whole product feels like one coherent experience.
///
/// v2.0 spec:
///   * Page transitions  -> [FadeBouncePageRoute] (fade + 0.92->1.0 scale bounce)
///   * Modal-ish screens -> [SlideUpRoute] (bottom sheet feel, no context)
///   * List stagger      -> [AppMotion.stagger]
///   * Micro feedback    -> [AppMotion.fast] + [AppMotion.bounceIn]
class AppMotion {
  // ---------------------------------------------------------------- timings
  /// Tooltip / chip / icon micro-feedback.
  static const Duration instant = Duration(milliseconds: 120);

  /// Buttons, selection rings, small containers.
  static const Duration fast = Duration(milliseconds: 200);

  /// Default container morph / page transition length.
  static const Duration medium = Duration(milliseconds: 350);

  /// Bigger cards, hero-adjacent elements.
  static const Duration slow = Duration(milliseconds: 500);

  /// Splash logo, onboarding hero pieces.
  static const Duration verySlow = Duration(milliseconds: 800);

  /// Full choreography sequences (splash -> app).
  static const Duration hero = Duration(milliseconds: 1100);

  // ----------------------------------------------------------------- curves
  /// Entrance with a light overshoot (cards popping in).
  static const Curve bounceIn = Curves.easeOutBack;

  /// Exit with anticipation.
  static const Curve bounceOut = Curves.easeInBack;

  /// Elastic pop — badges, confetti, price tags.
  static const Curve popIn = Curves.elasticOut;

  /// Standard decelerating entrance.
  static const Curve smoothIn = Curves.easeOutCubic;

  /// Standard accelerating exit.
  static const Curve smoothOut = Curves.easeInCubic;

  /// Symmetric glide (position swaps, drawers).
  static const Curve glide = Curves.easeInOutCubic;

  // ---------------------------------------------------------------- stagger
  /// Builds a staggered [Interval] for list item [index] out of [total].
  ///
  /// Example — first 6 items of a feed animate 0ms..300ms, 40ms apart:
  /// ```dart
  /// final t = AppMotion.stagger(i, items.length);
  /// FadeTransition(opacity: t, child: ...);
  /// ```
  static Interval stagger(int index, int total, {double overlap = 0.7}) {
    final int count = total.clamp(1, 8); // only stagger the visible head
    if (index >= count) return const Interval(1.0, 1.0);
    final double span = 1.0 / count;
    final double start = (index * span * (1.0 - overlap)).clamp(0.0, 0.9);
    final double end = (start + span * (1.0 + overlap)).clamp(0.0, 1.0);
    return Interval(start, end, curve: Curves.easeOutCubic);
  }

  /// Springy scale tween used for pop-in badges.
  static Tween<double> get popScale => Tween<double>(begin: 0.6, end: 1.0);

  /// Standard route transition scale tween (0.92 -> 1.0).
  static Tween<double> get routeScale => Tween<double>(begin: 0.92, end: 1.0);
}

/// The v2.0 signature page transition: cross-fade with a subtle
/// scale-up bounce. Used for every named route in the app.
class FadeBouncePageRoute<T> extends PageRouteBuilder<T> {
  FadeBouncePageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
    super.opaque = true,
    super.transitionDuration = AppMotion.medium,
  }) : super(
          reverseTransitionDuration: AppMotion.fast,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.bounceIn,
              reverseCurve: AppMotion.smoothOut,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: AppMotion.routeScale.animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Bottom-sheet flavored route for immersive full-screen flows
/// (live commerce, AR try-on, wallet) — content slides up and fades.
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  SlideUpRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
    super.transitionDuration = AppMotion.slow,
  }) : super(
          opaque: true,
          reverseTransitionDuration: AppMotion.medium,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.smoothIn,
              reverseCurve: AppMotion.smoothOut,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

/// Wraps any widget in the standard v2.0 press feedback:
/// a light scale-down while the pointer is down.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: AppMotion.instant,
        curve: _pressed ? AppMotion.smoothOut : AppMotion.bounceIn,
        child: widget.child,
      ),
    );
  }
}

/// Plug-in for [ThemeData.pageTransitionsTheme] so that even ad-hoc
/// `MaterialPageRoute` pushes obey the v2.0 motion standard.
class FadeBounceTransitionsBuilder extends PageTransitionsBuilder {
  const FadeBounceTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.bounceIn,
      reverseCurve: AppMotion.smoothOut,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: AppMotion.routeScale.animate(curved),
        child: child,
      ),
    );
  }
}

/// v2 kept a second, smaller set of timings and curves alongside [AppMotion]
/// — these are the ones its splash and onboarding are actually built on, so
/// they are carried over exactly rather than mapped onto the other scale.
/// The numbers differ ([fast] is 150ms here, 200ms there); collapsing them
/// would change how the introduction feels.
class AppAnimations {
  const AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;
}
