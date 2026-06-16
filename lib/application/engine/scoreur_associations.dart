import 'package:riverpod/riverpod.dart';

import '../../domain/enums/famille_effet_association.dart';
import '../../domain/enums/niveau_confiance.dart';
import '../../domain/value_objects/profil_ponderation_associations.dart';
import 'suggestion_association.dart';

/// Pure calculator that **scores** a derived association (ADR-0011) so the UI can
/// rank and prune suggestions and the recommendation engine can weight them.
///
/// `score(bénéfice) = poids(familleEffet(mécanisme)) × facteurConfiance`.
/// Conflicts are *warnings*, not preferences: they are not weighted by the
/// profile — only ordered by confidence. Stateless; the [ProfilPonderationAssociations]
/// is passed in, keeping the calculator dependency-free and testable.
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

  /// Score of [s] under [profil]. A benefit is weighted by its effect family;
  /// a conflict is scored by confidence alone. Always `>= 0`; an `ignore`d
  /// family yields `0` (the suggestion can then be dropped).
  double score(SuggestionAssociation s, ProfilPonderationAssociations profil) {
    final facteur = _facteur(s.confiance);
    return switch (s) {
      SuggestionBenefique(:final mecanisme) =>
        profil.multiplicateur(familleDe(mecanisme)) * facteur,
      SuggestionConflit() => facteur,
    };
  }

  /// Whether [s] should be shown at all: a benefit whose family is `ignore`d
  /// (score `0`) is dropped; conflicts are always kept (warnings).
  bool estRetenue(SuggestionAssociation s, ProfilPonderationAssociations profil) =>
      s is SuggestionConflit || score(s, profil) > 0;
}

/// DI provider for the (stateless) [ScoreurAssociations].
final scoreurAssociationsProvider = Provider<ScoreurAssociations>(
  (ref) => const ScoreurAssociations(),
);
