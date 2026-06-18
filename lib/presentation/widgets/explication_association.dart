import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/critere_association.dart';
import '../../l10n/app_localizations.dart';

/// Builds the **full, explicit list of factors** behind a derived association
/// (ADR-0014, Décision 1/2): one localised sentence per [CritereAssociation] the
/// engine evaluated, **with the real values** read from the two sheets — so the
/// user sees every variable that entered the calculation, never a vague phrase.
///
/// [source] is the plant providing the service / driving the conflict, [cible]
/// the other one (resolved from the association's direction by the caller).
/// Criteria are rendered in [CritereAssociation] declaration order for a stable
/// reading order, regardless of the set's iteration order.
List<String> facteursAssociation(
  AppLocalizations l10n,
  Set<CritereAssociation> criteres,
  FichePlante source,
  FichePlante cible,
) {
  final s = source.nomLocalise('fr');
  final c = cible.nomLocalise('fr');
  String hauteur(FichePlante f) => '${f.hauteurAdulteCmMax ?? f.hauteurAdulteCmMin ?? '?'}';

  String ligne(CritereAssociation cr) => switch (cr) {
        CritereAssociation.sourceFixeAzote => l10n.critereSourceFixeAzote(s),
        CritereAssociation.cibleGourmandeAzote =>
          l10n.critereCibleGourmandeAzote(c),
        CritereAssociation.sourceAttirePollinisateurs =>
          l10n.critereSourceAttirePollinisateurs(s),
        CritereAssociation.cibleEntomophile => l10n.critereCibleEntomophile(c),
        CritereAssociation.sourceAttireAuxiliaires =>
          l10n.critereSourceAttireAuxiliaires(s),
        CritereAssociation.cibleSujetteRavageurs =>
          l10n.critereCibleSujetteRavageurs(c),
        CritereAssociation.sourceSupport => l10n.critereSourceSupport(s),
        CritereAssociation.sourcePlusHaute => l10n.critereSourcePlusHaute(s),
        CritereAssociation.cibleGrimpante => l10n.critereCibleGrimpante(c),
        CritereAssociation.sourceHaute =>
          l10n.critereSourceHaute(s, hauteur(source)),
        CritereAssociation.cibleNettementPlusBasse =>
          l10n.critereCiblePlusBasse(c, hauteur(cible)),
        CritereAssociation.ciblePrefereOmbre => l10n.critereCiblePrefereOmbre(c),
        CritereAssociation.cibleTolereOmbre => l10n.critereCibleTolereOmbre(c),
        CritereAssociation.cyclesComplementaires =>
          l10n.critereCyclesComplementaires,
        CritereAssociation.occupationsDecalees =>
          l10n.critereOccupationsDecalees,
        CritereAssociation.sourceCouvreSol => l10n.critereSourceCouvreSol(s),
        CritereAssociation.sourceBriseVent => l10n.critereSourceBriseVent(s),
        CritereAssociation.deuxAromatiques => l10n.critereDeuxAromatiques,
        CritereAssociation.uneRepulsive => l10n.critereUneRepulsive,
        CritereAssociation.sourceRepulsiveCible =>
          l10n.critereSourceRepulsiveCible(s, c),
        CritereAssociation.sourcePiegeCible =>
          l10n.critereSourcePiegeCible(s, c),
        CritereAssociation.sourceRacineProfonde =>
          l10n.critereSourceRacineProfonde(s),
        CritereAssociation.cibleRacineSuperficielle =>
          l10n.critereCibleRacineSuperficielle(c),
        CritereAssociation.memeFamille =>
          l10n.critereMemeFamille(source.familleBotanique),
        CritereAssociation.deuxHautesPleinSoleil =>
          l10n.critereDeuxHautesPleinSoleil,
        CritereAssociation.deuxGourmandesAzote =>
          l10n.critereDeuxGourmandesAzote,
        CritereAssociation.deuxAssoiffees => l10n.critereDeuxAssoiffees,
        CritereAssociation.deuxEtalees => l10n.critereDeuxEtalees,
        CritereAssociation.maladieCommune => l10n.critereMaladieCommune,
      };

  return [
    for (final cr in CritereAssociation.values)
      if (criteres.contains(cr)) ligne(cr),
  ];
}
