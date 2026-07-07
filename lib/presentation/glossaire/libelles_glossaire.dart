import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'chapitre_glossaire.dart';
import 'type_terme_glossaire.dart';

/// French labels & icons for the glossary enums (ADR-0017), mirroring the
/// `LibellesEnums` pattern: exhaustive `switch`es so adding a value is a
/// compile error until its label is provided.
extension LibellesGlossaire on AppLocalizations {
  /// Label for a glossary chapter.
  String chapitreGlossaire(ChapitreGlossaire c) => switch (c) {
        ChapitreGlossaire.culturesEtPlantes => glossaireChapCultures,
        ChapitreGlossaire.famillesBotaniques => glossaireChapFamilles,
        ChapitreGlossaire.santeDuJardin => glossaireChapSante,
        ChapitreGlossaire.solEtTerre => glossaireChapSol,
        ChapitreGlossaire.eauEtArrosage => glossaireChapEau,
        ChapitreGlossaire.outilsEtEquipements => glossaireChapOutils,
        ChapitreGlossaire.climatEtSaisons => glossaireChapClimat,
        ChapitreGlossaire.associationsEtCompagnonnage =>
          glossaireChapAssociations,
        ChapitreGlossaire.gestesEtOrganisation => glossaireChapGestes,
      };

  /// Label for a glossary term kind (badge on the term page).
  String typeTermeGlossaire(TypeTermeGlossaire t) => switch (t) {
        TypeTermeGlossaire.famille => glossaireTypeFamille,
        TypeTermeGlossaire.maladie => glossaireTypeMaladie,
        TypeTermeGlossaire.ravageur => glossaireTypeRavageur,
        TypeTermeGlossaire.outil => glossaireTypeOutil,
        TypeTermeGlossaire.notion => glossaireTypeNotion,
      };
}

/// Material icon for a glossary chapter (Phosphor pending — docs/08 §7).
IconData iconeChapitreGlossaire(ChapitreGlossaire c) => switch (c) {
      ChapitreGlossaire.culturesEtPlantes => Icons.eco_outlined,
      ChapitreGlossaire.famillesBotaniques => Icons.account_tree_outlined,
      ChapitreGlossaire.santeDuJardin => Icons.healing_outlined,
      ChapitreGlossaire.solEtTerre => Icons.landscape_outlined,
      ChapitreGlossaire.eauEtArrosage => Icons.water_drop_outlined,
      ChapitreGlossaire.outilsEtEquipements => Icons.handyman_outlined,
      ChapitreGlossaire.climatEtSaisons => Icons.wb_sunny_outlined,
      ChapitreGlossaire.associationsEtCompagnonnage => Icons.hub_outlined,
      ChapitreGlossaire.gestesEtOrganisation => Icons.checklist_outlined,
    };
