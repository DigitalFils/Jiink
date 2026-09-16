import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets/logo.dart';

/// Renders the launcher icon so it can be screenshotted, at the exact sizes
/// Android's mipmap buckets want.
///
/// The icon is [S8LLMark] — the same widget the splash animates in — rather
/// than a separate drawing of the same idea, so the thing on the home
/// screen and the thing inside the app cannot drift apart. The glow is off:
/// a soft shadow bleeding to the edge of a launcher icon reads as a
/// compression artifact once the system masks it to a circle.
///
///   flutter build web -t lib/dev_icon.dart --release --no-web-resources-cdn
///
/// then screenshot each `#icon-<size>` box. Nothing imports this; it is
/// tree-shaken out of the app build.
void main() => runApp(const DevIconApp());

/// mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi, plus a 1024 master for the stores.
const iconSizes = <int>[48, 72, 96, 144, 192, 1024];

class DevIconApp extends StatelessWidget {
  const DevIconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: S8llColors.black,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final size in iconSizes)
                Padding(
                  // Space between boxes so a screenshot clip of one can't
                  // pick up a neighbour's edge.
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: size.toDouble(),
                    height: size.toDouble(),
                    // The mark drawn edge to edge. Android masks it to the
                    // launcher's shape, and the mark's own rounding sits
                    // inside that safely.
                    // Full bleed: no rounding, no glow. Android masks the
                    // icon to the launcher's shape, so pre-rounded corners
                    // only leave dead pixels inside that mask, and the
                    // lime running to the edge is what lets the same PNG
                    // serve as the adaptive foreground once the lime is
                    // keyed out.
                    child: S8LLMark(
                      size: size.toDouble(),
                      glow: false,
                      radiusRatio: 0,
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
