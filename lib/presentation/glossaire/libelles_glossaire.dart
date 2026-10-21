import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'chapitre_glossaire.dart';
import 'type_terme_glossaire.dart';

/// French labels & icons for the glossary enums, mirroring the
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

/// Icon of a glossary chapter.
IconData iconeChapitreGlossaire(ChapitreGlossaire c) => switch (c) {
      ChapitreGlossaire.culturesEtPlantes => PhosphorIconsRegular.leaf,
      ChapitreGlossaire.famillesBotaniques => PhosphorIconsRegular.treeStructure,
      ChapitreGlossaire.santeDuJardin => PhosphorIconsRegular.bandaids,
      ChapitreGlossaire.solEtTerre => PhosphorIconsRegular.mountains,
      ChapitreGlossaire.eauEtArrosage => PhosphorIconsRegular.drop,
      ChapitreGlossaire.outilsEtEquipements => PhosphorIconsRegular.wrench,
      ChapitreGlossaire.climatEtSaisons => PhosphorIconsRegular.sun,
      ChapitreGlossaire.associationsEtCompagnonnage => PhosphorIconsRegular.graph,
      ChapitreGlossaire.gestesEtOrganisation => PhosphorIconsRegular.listChecks,
    };
