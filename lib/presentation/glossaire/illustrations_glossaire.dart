/// Registry of the glossary illustrations (ADR-0017, D4 / Lot 5).
///
/// One file per illustrated term: `assets/images/glossaire/<term id>.webp`
/// (lightweight WebP, capped dimensions), provenance and licence recorded in
/// `assets/images/glossaire/SOURCES.txt`. Population is **incremental**: a
/// term absent from this set simply renders no image block.
///
/// Pure Dart (no Flutter import) on purpose: the reference lint
/// (`tool/verifier_referentiels.dart`, run with `dart run`) imports this set
/// to flag orphan image files and missing SOURCES.txt entries, and the
/// glossary integrity test checks every entry resolves to a real term and an
/// existing asset — adding an image without registering it here (or the
/// reverse) breaks the suite.
library;

/// Asset directory of the glossary illustrations.
const String dossierIllustrationsGlossaire = 'assets/images/glossaire';

/// Ids of the glossary terms that currently have an illustration.
const Set<String> idsIllustres = {
  'outil.oya',
  'outil.cloche',
  'outil.chassis',
  'outil.recuperateur-eau',
  'outil.hotel-a-insectes',
  'notion.sol-argileux',
};

/// Asset path of the illustration of [idTerme], or `null` when the term has
/// none (D4: no image block is rendered).
String? illustrationDe(String idTerme) => idsIllustres.contains(idTerme)
    ? '$dossierIllustrationsGlossaire/$idTerme.webp'
    : null;
