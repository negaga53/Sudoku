import 'package:flutter/material.dart';
import 'package:sudoku_app/utils/constants.dart';

/// Reusable animation helpers for Sudoku cell interactions.
class CellAnimations {
  CellAnimations._();

  // ---------------------------------------------------------------------------
  // Controller factories
  // ---------------------------------------------------------------------------

  /// Creates an [AnimationController] pre-configured for the error-shake effect.
  static AnimationController createShakeController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Creates an [AnimationController] for the pop-in scale effect.
  static AnimationController createPopInController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: AppConstants.animationDuration,
    );
  }

  /// Creates an [AnimationController] for the selection pulse glow.
  static AnimationController createPulseController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1200),
    );
  }

  // ---------------------------------------------------------------------------
  // Shake animation (error state)
  // ---------------------------------------------------------------------------

  /// Returns a horizontal offset animation that shakes 3 times.
  ///
  /// Usage:
  /// ```dart
  /// Transform.translate(
  ///   offset: Offset(CellAnimations.shakeOffset(controller).value, 0),
  ///   child: ...
  /// )
  /// ```
  static Animation<double> shakeAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Plays the shake animation once, then resets.
  static void playShake(AnimationController controller) {
    controller.forward(from: 0);
  }

  // ---------------------------------------------------------------------------
  // Pop-in animation (number placement)
  // ---------------------------------------------------------------------------

  /// Scale animation from 0 → 1 with a slight overshoot (elasticOut).
  static Animation<double> popInAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticOut),
    );
  }

  /// Plays the pop-in animation from the beginning.
  static void playPopIn(AnimationController controller) {
    controller.forward(from: 0);
  }

  // ---------------------------------------------------------------------------
  // Selection pulse (glow border)
  // ---------------------------------------------------------------------------

  /// Returns a repeating 0 → 1 → 0 animation suitable for a glow opacity.
  static Animation<double> pulseAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  /// Starts the pulse as a repeating animation.
  static void startPulse(AnimationController controller) {
    controller.repeat(reverse: true);
  }

  /// Stops the pulse and resets.
  static void stopPulse(AnimationController controller) {
    controller.stop();
    controller.reset();
  }

  // ---------------------------------------------------------------------------
  // Celebration animation (number fully placed)
  // ---------------------------------------------------------------------------

  /// Creates an [AnimationController] for the celebration scale-pulse.
  static AnimationController createCelebrateController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    );
  }

  /// Scale animation: 1.0 → 1.25 → 1.0 with a bounce.
  static Animation<double> celebrateAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Plays the celebration animation once.
  static void playCelebrate(AnimationController controller) {
    controller.forward(from: 0);
  }
}
