import 'package:flutter/widgets.dart';

/// Spacing scale of the **« Carnet vivant »** design system (base 4px).
///
/// From `docs/08-design-system.md` §5. Layout code must pull spacing from these
/// tokens — **no arbitrary values** (no 17px, 22px…). The names map 1:1 to the
/// `space-1` … `space-8` tokens in the docs.
abstract final class EspacementsApp {
  const EspacementsApp._();

  /// 4px — icon ↔ text.
  static const double s1 = 4;

  /// 8px — compact padding (badges).
  static const double s2 = 8;

  /// 12px — button padding, dense lists.
  static const double s3 = 12;

  /// 16px — standard card padding.
  static const double s4 = 16;

  /// 24px — between sections.
  static const double s5 = 24;

  /// 32px — screen side margins.
  static const double s6 = 32;

  /// 48px — block separation.
  static const double s7 = 48;

  /// 64px — empty screens, onboarding.
  static const double s8 = 64;
}

/// Corner radius tokens of the **« Carnet vivant »** design system.
///
/// From `docs/08-design-system.md` §6.
abstract final class RayonsApp {
  const RayonsApp._();

  /// 6px — chips, tags, small inputs.
  static const Radius sm = Radius.circular(6);

  /// 8px — buttons, standard inputs.
  static const Radius md = Radius.circular(8);

  /// 12px — cards, lists, containers.
  static const Radius lg = Radius.circular(12);

  /// 24px — modals, sheets, popovers.
  static const Radius xl = Radius.circular(24);

  /// 9999px — avatars, FAB, round shapes.
  static const Radius full = Radius.circular(9999);

  /// [BorderRadius.all] of [sm].
  static const BorderRadius brSm = BorderRadius.all(sm);

  /// [BorderRadius.all] of [md].
  static const BorderRadius brMd = BorderRadius.all(md);

  /// [BorderRadius.all] of [lg].
  static const BorderRadius brLg = BorderRadius.all(lg);

  /// [BorderRadius.all] of [xl].
  static const BorderRadius brXl = BorderRadius.all(xl);
}

/// Phosphor-aligned icon sizes (`docs/08-design-system.md` §7).
///
/// The default everywhere is [md] (20). A bare icon must always carry a label or
/// tooltip — enforce that at the call site, not here.
abstract final class TaillesIconesApp {
  const TaillesIconesApp._();

  /// 16px.
  static const double sm = 16;

  /// 20px — default.
  static const double md = 20;

  /// 24px.
  static const double lg = 24;

  /// 32px.
  static const double xl = 32;

  /// 48px+ — empty-state illustrations.
  static const double xl2 = 48;
}
