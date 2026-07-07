import '../../../domain/enums/charge_tuteur.dart';
import '../../../domain/enums/etat_equipement.dart';
import '../../../domain/enums/type_equipement.dart';
import '../../../l10n/app_localizations.dart';
import '../chapitre_glossaire.dart';
import '../complement_terme.dart';
import '../terme_glossaire.dart';
import '../type_terme_glossaire.dart';

/// « Outils & équipements » chapter of the catalogue (ADR-0017 Lot 4): **one
/// page per [TypeEquipement] value** (D1/annexe A), plus the equipment-state
/// scale. [TypeEquipement.autre] is the only value without a page — it names
/// nothing concrete to explain.
List<TermeGlossaire> construireOutils(AppLocalizations l10n) => [
      for (final v in TypeEquipement.values)
        if (v != TypeEquipement.autre) _pageOutil(l10n, v),
      TermeGlossaire(
        id: TermeGlossaire.idNotion('etat-equipement'),
        chapitre: ChapitreGlossaire.outilsEtEquipements,
        type: TypeTermeGlossaire.notion,
        titre: l10n.glossaireNotionEtatEquipementTitre,
        definition: l10n.glossaireNotionEtatEquipementDef,
        complements: [
          ComplementValeursEnum(valeurs: [
            for (final v in EtatEquipement.values)
              (
                libelle: switch (v) {
                  EtatEquipement.neuf => l10n.glossaireValEtatNeuf,
                  EtatEquipement.bon => l10n.glossaireValEtatBon,
                  EtatEquipement.use => l10n.glossaireValEtatUse,
                  EtatEquipement.aRemplacer => l10n.glossaireValEtatARemplacer,
                  EtatEquipement.horsService =>
                    l10n.glossaireValEtatHorsService,
                },
                description: null,
              ),
          ]),
        ],
      ),
    ];

/// Glossary id of a tool page (`outil.<slug>`), one per concrete
/// [TypeEquipement] value. Public for the coverage map and cross-links.
String idOutilEquipement(TypeEquipement v) => TermeGlossaire.idOutil(switch (v) {
      TypeEquipement.oya => 'oya',
      TypeEquipement.gouttesAGoutte => 'goutte-a-goutte',
      TypeEquipement.tuteur => 'tuteur',
      TypeEquipement.treillis => 'treillis',
      TypeEquipement.tunnel => 'tunnel',
      TypeEquipement.serreSemis => 'serre-a-semis',
      TypeEquipement.chassis => 'chassis',
      TypeEquipement.cloche => 'cloche',
      TypeEquipement.voileHivernage => 'voile-hivernage',
      TypeEquipement.filetAntiInsecte => 'filet-anti-insecte',
      TypeEquipement.hotelInsectes => 'hotel-a-insectes',
      TypeEquipement.composteur => 'composteur',
      TypeEquipement.recuperateurEau => 'recuperateur-eau',
      TypeEquipement.autre =>
        throw ArgumentError('TypeEquipement.autre has no glossary page'),
    });

TermeGlossaire _pageOutil(AppLocalizations l10n, TypeEquipement v) {
  final (String titre, String definition, String? astuce, String? conseil) =
      switch (v) {
    TypeEquipement.oya => (
        l10n.glossaireOutilOyaTitre,
        l10n.glossaireOutilOyaDef,
        l10n.glossaireOutilOyaAstuce,
        null
      ),
    TypeEquipement.gouttesAGoutte => (
        l10n.glossaireOutilGoutteAGoutteTitre,
        l10n.glossaireOutilGoutteAGoutteDef,
        null,
        l10n.glossaireOutilGoutteAGoutteConseil1
      ),
    TypeEquipement.tuteur => (
        l10n.glossaireOutilTuteurTitre,
        l10n.glossaireOutilTuteurDef,
        l10n.glossaireOutilTuteurAstuce,
        null
      ),
    TypeEquipement.treillis => (
        l10n.glossaireOutilTreillisTitre,
        l10n.glossaireOutilTreillisDef,
        null,
        null
      ),
    TypeEquipement.tunnel => (
        l10n.glossaireOutilTunnelTitre,
        l10n.glossaireOutilTunnelDef,
        null,
        l10n.glossaireOutilTunnelConseil1
      ),
    TypeEquipement.serreSemis => (
        l10n.glossaireOutilSerreSemisTitre,
        l10n.glossaireOutilSerreSemisDef,
        null,
        null
      ),
    TypeEquipement.chassis => (
        l10n.glossaireOutilChassisTitre,
        l10n.glossaireOutilChassisDef,
        null,
        null
      ),
    TypeEquipement.cloche => (
        l10n.glossaireOutilClocheTitre,
        l10n.glossaireOutilClocheDef,
        null,
        l10n.glossaireOutilClocheConseil1
      ),
    TypeEquipement.voileHivernage => (
        l10n.glossaireOutilVoileHivernageTitre,
        l10n.glossaireOutilVoileHivernageDef,
        l10n.glossaireOutilVoileHivernageAstuce,
        null
      ),
    TypeEquipement.filetAntiInsecte => (
        l10n.glossaireOutilFiletAntiInsecteTitre,
        l10n.glossaireOutilFiletAntiInsecteDef,
        null,
        l10n.glossaireOutilFiletAntiInsecteConseil1
      ),
    TypeEquipement.hotelInsectes => (
        l10n.glossaireOutilHotelInsectesTitre,
        l10n.glossaireOutilHotelInsectesDef,
        null,
        l10n.glossaireOutilHotelInsectesConseil1
      ),
    TypeEquipement.composteur => (
        l10n.glossaireOutilComposteurTitre,
        l10n.glossaireOutilComposteurDef,
        null,
        l10n.glossaireOutilComposteurConseil1
      ),
    TypeEquipement.recuperateurEau => (
        l10n.glossaireOutilRecuperateurEauTitre,
        l10n.glossaireOutilRecuperateurEauDef,
        l10n.glossaireOutilRecuperateurEauAstuce,
        null
      ),
    TypeEquipement.autre =>
      throw ArgumentError('TypeEquipement.autre has no glossary page'),
  };
  return TermeGlossaire(
    id: idOutilEquipement(v),
    chapitre: ChapitreGlossaire.outilsEtEquipements,
    type: TypeTermeGlossaire.outil,
    titre: titre,
    definition: definition,
    astuce: astuce,
    conseils: [?conseil],
    complements: [
      // The stake page also explains the climber-load scale the association
      // engine uses to size a support (ChargeTuteur, ADR-0010).
      if (v == TypeEquipement.tuteur)
        ComplementValeursEnum(valeurs: [
          for (final c in ChargeTuteur.values)
            switch (c) {
              ChargeTuteur.legere => (
                  libelle: l10n.glossaireValChargeLegere,
                  description: l10n.glossaireValChargeLegereDesc
                ),
              ChargeTuteur.moyenne => (
                  libelle: l10n.glossaireValChargeMoyenne,
                  description: l10n.glossaireValChargeMoyenneDesc
                ),
              ChargeTuteur.lourde => (
                  libelle: l10n.glossaireValChargeLourde,
                  description: l10n.glossaireValChargeLourdeDesc
                ),
            },
        ]),
      if (v == TypeEquipement.tuteur)
        ComplementVoirAussi(ids: [
          TermeGlossaire.idNotion('meca-tuteur-structurel'),
          TermeGlossaire.idOutil('treillis'),
        ]),
    ],
  );
}
