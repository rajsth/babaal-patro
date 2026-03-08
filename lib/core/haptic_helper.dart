import 'package:flutter/services.dart';

/// Safe haptic feedback wrapper — silently no-ops on devices
/// without a Taptic Engine (e.g. iPads).
class Haptic {
  Haptic._();

  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
