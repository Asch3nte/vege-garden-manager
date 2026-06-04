/// Lifecycle status of a plantation.
///
/// `enCours` is the only non-terminal status; the three others end the
/// plantation and require an end date. See `docs/05-modele-de-domaine.md` §5.
enum StatutPlantation { enCours, recoltee, echouee, arrachee }

/// Whether the status ends the plantation's life.
extension StatutPlantationX on StatutPlantation {
  bool get estTerminal => this != StatutPlantation.enCours;
}
