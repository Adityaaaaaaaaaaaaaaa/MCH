// lib/utils/adaptive_transition.dart
import 'package:flutter/material.dart';

enum PageWeight { light, medium, heavy }

typedef _Builder = Widget Function(Widget child, Animation<double> a);

// Material 3 emphasized curves (snappy + smooth)
const Cubic _kEmphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
const Cubic _kEmphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

class TransitionSpec {
  final Duration duration;
  final Curve curveIn;   // applied to incoming child
  final Curve curveOut;  // applied to outgoing child
  // ignore: library_private_types_in_public_api
  final _Builder builder;

  const TransitionSpec(this.duration, this.curveIn, this.curveOut, this.builder);

  factory TransitionSpec.from(PageWeight w, {required bool stressed}) {
    // Under load: cheapest and smoothest (keeps 60/120Hz happy)
    if (stressed) {
      return TransitionSpec(
        const Duration(milliseconds: 220),
        _kEmphasizedDecelerate,
        _kEmphasizedAccelerate,
        (child, a) => FadeTransition(opacity: a, child: child),
      );
    }

    switch (w) {
      case PageWeight.heavy:
        // Fade + micro-scale + micro vertical settle.
        // Masks expensive first-builds (images/layout) without feeling “zoomy”.
        return TransitionSpec(
          const Duration(milliseconds: 260),
          _kEmphasizedDecelerate,
          _kEmphasizedAccelerate,
          (child, a) {
            final fade  = CurvedAnimation(parent: a, curve: Curves.easeOut);
            final scale = Tween<double>(begin: 0.985, end: 1.0).animate(a);
            final slide = Tween<Offset>(begin: const Offset(0, 0.008), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(a);
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: SlideTransition(position: slide, child: child),
              ),
            );
          },
        );

      case PageWeight.medium:
        // Short horizontal slide + fade — reads as quick but not abrupt.
        return TransitionSpec(
          const Duration(milliseconds: 200),
          _kEmphasizedDecelerate,
          _kEmphasizedAccelerate,
          (child, a) {
            final slide = Tween<Offset>(begin: const Offset(0.015, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(a);
            return FadeTransition(
              opacity: a,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );

      case PageWeight.light:
      // Fade-through with a tiny settle scale; feels instantaneous.
        return TransitionSpec(
          const Duration(milliseconds: 160),
          _kEmphasizedDecelerate,
          _kEmphasizedAccelerate,
          (child, a) {
            final scale = Tween<double>(begin: 0.995, end: 1.0).animate(a);
            return FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
        );
    }
  }
}

/// Declare your route weights here; tweak any time.
const Map<String, PageWeight> kRouteWeights = {
  '/': PageWeight.light,
  '/splash': PageWeight.light,
  '/signin': PageWeight.light,
  '/home': PageWeight.light,
  '/settings': PageWeight.medium,
  '/preferences': PageWeight.medium,
  '/scan': PageWeight.light,
  '/scanFood': PageWeight.heavy,
  '/scanReceipt': PageWeight.heavy,
  '/reviewScreen': PageWeight.medium,
  '/manualInput': PageWeight.medium,
  '/cook': PageWeight.light,
  '/searchRecipe': PageWeight.medium,
  '/recipePage': PageWeight.heavy,
  '/inventory': PageWeight.heavy,
  '/planner': PageWeight.heavy,
  '/cravings': PageWeight.heavy,
  '/cravingRecipe': PageWeight.heavy,
  '/history': PageWeight.medium,
  '/favourites': PageWeight.medium,
  '/shopping': PageWeight.medium,
};
