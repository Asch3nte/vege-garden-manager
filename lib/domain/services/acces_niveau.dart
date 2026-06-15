import '../enums/niveau_experience.dart';

/// Progressive-disclosure access policy (ADR-0009).
///
/// Maps a user [NiveauExperience] to the features it unlocks. **Single source of
/// truth**: the UI asks this policy (`acces.vueReseau`, `acces.solTexturePh`…)
/// instead of scattering `if (niveau == ...)` checks. Pure and read-only, so it
/// respects the reversibility guard — it only governs **display**, never the
/// stored data.
///
/// Tiers (ADR-0009 Décision 2):
/// - **Débutant**: the core loop only.
/// - **Intermédiaire**: tools, soil techniques, network view, observations,
///   season view, multi-garden, per-category notifications, lunar option.
/// - **Expert**: soil texture/pH, dashboard stats, advanced rotation, custom
///   fiches, detailed water needs (else coarse).
class AccesNiveau {
  final NiveauExperience _niveau;

  const AccesNiveau(this._niveau);

  /// The level this policy reflects.
  NiveauExperience get niveau => _niveau;

  bool get _intermediaireOuPlus => _niveau != NiveauExperience.debutant;
  bool get _expert => _niveau == NiveauExperience.expert;

  // --- Intermédiaire et plus ---

  /// Equipment / tools (`Equipement`).
  bool get equipements => _intermediaireOuPlus;

  /// Soil techniques (lasagne, butte, paillage, no-dig — `TechniqueSol`).
  bool get techniquesSol => _intermediaireOuPlus;

  /// Catalogue "Réseau" association view.
  bool get vueReseau => _intermediaireOuPlus;

  /// Observations (journal).
  bool get observations => _intermediaireOuPlus;

  /// Calendar "Saison" (sowing→harvest) view.
  bool get vueSaison => _intermediaireOuPlus;

  /// Managing several gardens.
  bool get multiPotager => _intermediaireOuPlus;

  /// Per-category notification toggles (débutant sees only the master switch).
  bool get notificationsParCategorie => _intermediaireOuPlus;

  /// Lunar-calendar option (available from intermédiaire).
  bool get calendrierLunaire => _intermediaireOuPlus;

  // --- Expert ---

  /// Soil texture + pH per zone.
  bool get solTexturePh => _expert;

  /// Dashboard statistics (season harvests…).
  bool get statsTableauBord => _expert;

  /// Advanced rotation (precedents, return delay).
  bool get rotationAvancee => _expert;

  /// Custom plant fiches (contribution).
  bool get fichesPerso => _expert;

  /// Detailed water needs (frequency/quantities). Lower tiers see the coarse
  /// term (a lot / moderate / little).
  bool get eauDetaillee => _expert;

  /// The next tier to suggest in a "level-up" teaser, or `null` at the top.
  NiveauExperience? get palierSuivant => switch (_niveau) {
        NiveauExperience.debutant => NiveauExperience.intermediaire,
        NiveauExperience.intermediaire => NiveauExperience.expert,
        NiveauExperience.expert => null,
      };
}
