import 'package:riverpod/riverpod.dart';

import '../../domain/enums/famille_effet_association.dart';
import '../../domain/enums/famille_effet_conflit.dart';
import '../../domain/enums/niveau_confiance.dart';
import '../../domain/value_objects/profil_ponderation_associations.dart';
import 'suggestion_association.dart';

/// Pure calculator that **scores** a derived association (ADR-0011) so the UI can
/// rank and prune suggestions and the recommendation engine can weight them.
///
/// `score(bénéfice) = poids(familleEffet(mécanisme)) × facteurConfiance` and,
/// since ADR-0014, `score(conflit) = poids(familleConflit(mécanisme)) ×
/// facteurConfiance` — so the user can prioritise (or ignore) a class of warnings
/// too. Stateless; the [ProfilPonderationAssociations] is passed in, keeping the
/// calculator dependency-free and testable.
class ScoreurAssociations {
  const ScoreurAssociations();

  /// Confidence multipliers (calibrable).
  static const double facteurEleve = 1.0;
  static const double facteurMoyen = 0.7;
  static const double facteurFaible = 0.4;

  static double _facteur(NiveauConfiance c) => switch (c) {
        NiveauConfiance.eleve => facteurEleve,
        NiveauConfiance.moyen => facteurMoyen,
        NiveauConfiance.faible => facteurFaible,
      };

  /// Score of [s] under [profil]: weighted by its effect family (benefit) or its
  /// conflict family (ADR-0014). Always `>= 0`; an `ignore`d family yields `0`
  /// (the suggestion is then dropped).
  double score(SuggestionAssociation s, ProfilPonderationAssociations profil) {
    final facteur = _facteur(s.confiance);
    return switch (s) {
      SuggestionBenefique(:final mecanisme) =>
        profil.multiplicateur(familleDe(mecanisme)) * facteur,
      SuggestionConflit(:final mecanisme) =>
        profil.multiplicateurConflit(familleConflitDe(mecanisme)) * facteur,
    };
  }

  /// Whether [s] should be shown at all: a benefit **or conflict** whose family
  /// is `ignore`d (score `0`) is dropped (ADR-0014).
  bool estRetenue(SuggestionAssociation s, ProfilPonderationAssociations profil) =>
      score(s, profil) > 0;
}

/// DI provider for the (stateless) [ScoreurAssociations].
final scoreurAssociationsProvider = Provider<ScoreurAssociations>(
  (ref) => const ScoreurAssociations(),
);
