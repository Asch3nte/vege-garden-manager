import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ephemeral (non-persisted) flag raised when the onboarding completes, read
/// **once** by the Potager screen to show a "tap a zone to add plants" hint.
///
/// Intentionally not stored in preferences: it is a one-off nudge shown right
/// after onboarding; a fresh app launch should not resurface it. The Potager
/// screen lowers it when the banner is dismissed.
class AstucePotagerZones extends Notifier<bool> {
  @override
  bool build() => false;

  /// Shows the hint (called when onboarding completes).
  void afficher() => state = true;

  /// Hides the hint (called when the banner is dismissed).
  void masquer() => state = false;
}

final astucePotagerZonesProvider =
    NotifierProvider<AstucePotagerZones, bool>(AstucePotagerZones.new);
