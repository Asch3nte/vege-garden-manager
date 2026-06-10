import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The zone a plant is about to be added to, carried across the "add a plant"
/// navigation (zone detail → catalogue → plant sheet → plantation form).
///
/// Immutable; [zoneNom] is kept only to label the catalogue banner without a
/// re-lookup.
class CibleAjoutPlante {
  final String zoneId;
  final String zoneNom;

  const CibleAjoutPlante({required this.zoneId, required this.zoneNom});

  @override
  bool operator ==(Object other) =>
      other is CibleAjoutPlante &&
      other.zoneId == zoneId &&
      other.zoneNom == zoneNom;

  @override
  int get hashCode => Object.hash(zoneId, zoneNom);
}

/// Holds the pending target zone for adding a plant, or `null` when the user is
/// browsing the catalogue freely (no zone pre-selected).
///
/// Presentation-only navigation state: when set, the catalogue shows an "adding
/// to a zone" banner and the plant sheet's CTA targets that zone directly;
/// when null, the CTA first asks the user to pick a zone on the plan.
class AjoutPlanteNotifier extends Notifier<CibleAjoutPlante?> {
  @override
  CibleAjoutPlante? build() => null;

  /// Targets [zoneId] (named [zoneNom]) for the next plant addition.
  void cibler({required String zoneId, required String zoneNom}) {
    state = CibleAjoutPlante(zoneId: zoneId, zoneNom: zoneNom);
  }

  /// Clears the pending target (addition done or cancelled).
  void effacer() => state = null;
}

/// The pending "add a plant" target zone (null = free catalogue browse).
final ajoutPlanteProvider =
    NotifierProvider<AjoutPlanteNotifier, CibleAjoutPlante?>(
  AjoutPlanteNotifier.new,
);
