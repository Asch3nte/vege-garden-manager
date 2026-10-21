import 'package:intl/intl.dart';

import '../../domain/enums/grandeur_mesure.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/enums/unite_quantite.dart';
import '../../domain/services/convertisseur_unites.dart';
import '../../domain/value_objects/preferences_unites.dart';
import '../../domain/value_objects/quantite.dart';
import '../../l10n/app_localizations.dart';

/// A unit a harvest can be typed in; imperial ones are stored converted.
enum UniteSaisieRecolte { g, kg, oz, lb, piece, botte, litre, ml, galUs, flOz }

/// Converts form entries between the chosen units and the stored metric.
class SaisieMesures {
  static const _convertisseur = ConvertisseurUnites();

  /// Plain number for a text field: up to two decimals, dot separator, as
  /// the fields parse it.
  static final NumberFormat _champ = NumberFormat('0.##', 'en');

  final PreferencesUnites _unites;

  const SaisieMesures(this._unites);

  bool _imperial(GrandeurMesure g) => _unites.pour(g) == SystemeUnites.imperial;

  String symboleSurface(AppLocalizations l10n) =>
      _imperial(GrandeurMesure.surface)
      ? l10n.symbolesSurfaceImperiale
      : l10n.symbolesSurfaceMetrique;

  String symboleLongueur(AppLocalizations l10n) =>
      _imperial(GrandeurMesure.longueur) ? l10n.saisiePouces : l10n.saisieCm;

  /// A surface typed in the chosen unit, in m².
  double surfaceVersM2(double saisie) => _imperial(GrandeurMesure.surface)
      ? _convertisseur.ft2VersM2(saisie)
      : saisie;

  /// A stored surface, as the field shows it.
  String surfacePourChamp(double m2) => _champ.format(
    _imperial(GrandeurMesure.surface) ? _convertisseur.m2VersFt2(m2) : m2,
  );

  /// A length typed in the chosen unit, in whole centimetres.
  int longueurVersCm(int saisie) => _imperial(GrandeurMesure.longueur)
      ? _convertisseur.poucesVersCentimetres(saisie.toDouble()).round()
      : saisie;

  /// A stored length, as the field shows it.
  String longueurPourChamp(int cm) => _imperial(GrandeurMesure.longueur)
      ? '${_convertisseur.centimetresVersPouces(cm.toDouble()).round()}'
      : '$cm';

  /// Harvest units offered, in the chosen mass and volume systems.
  List<UniteSaisieRecolte> get unitesRecolte => List.unmodifiable([
    ...(_imperial(GrandeurMesure.masse)
        ? [UniteSaisieRecolte.oz, UniteSaisieRecolte.lb]
        : [UniteSaisieRecolte.g, UniteSaisieRecolte.kg]),
    UniteSaisieRecolte.piece,
    UniteSaisieRecolte.botte,
    ...(_imperial(GrandeurMesure.volume)
        ? [UniteSaisieRecolte.galUs, UniteSaisieRecolte.flOz]
        : [UniteSaisieRecolte.litre, UniteSaisieRecolte.ml]),
  ]);

  /// The default harvest unit: the larger mass unit.
  UniteSaisieRecolte get uniteRecolteParDefaut =>
      _imperial(GrandeurMesure.masse)
      ? UniteSaisieRecolte.lb
      : UniteSaisieRecolte.kg;

  /// A typed harvest amount as a stored, metric [Quantite].
  Quantite quantite(double valeur, UniteSaisieRecolte unite) => switch (unite) {
    UniteSaisieRecolte.g => Quantite(valeur, UniteQuantite.g),
    UniteSaisieRecolte.kg => Quantite(valeur, UniteQuantite.kg),
    UniteSaisieRecolte.piece => Quantite(valeur, UniteQuantite.piece),
    UniteSaisieRecolte.botte => Quantite(valeur, UniteQuantite.botte),
    UniteSaisieRecolte.litre => Quantite(valeur, UniteQuantite.litre),
    UniteSaisieRecolte.ml => Quantite(valeur, UniteQuantite.ml),
    UniteSaisieRecolte.oz => Quantite(
      _convertisseur.oncesVersGrammes(valeur),
      UniteQuantite.g,
    ),
    UniteSaisieRecolte.lb => Quantite(
      _convertisseur.livresVersKilogrammes(valeur),
      UniteQuantite.kg,
    ),
    UniteSaisieRecolte.galUs => Quantite(
      _convertisseur.gallonsVersLitres(valeur),
      UniteQuantite.litre,
    ),
    UniteSaisieRecolte.flOz => Quantite(
      _convertisseur.oncesLiquidesVersMillilitres(valeur),
      UniteQuantite.ml,
    ),
  };

  static String libelle(AppLocalizations l10n, UniteSaisieRecolte u) =>
      switch (u) {
        UniteSaisieRecolte.g => l10n.uniteG,
        UniteSaisieRecolte.kg => l10n.uniteKg,
        UniteSaisieRecolte.piece => l10n.unitePiece,
        UniteSaisieRecolte.botte => l10n.uniteBotte,
        UniteSaisieRecolte.litre => l10n.uniteLitre,
        UniteSaisieRecolte.ml => l10n.uniteMl,
        UniteSaisieRecolte.oz => l10n.uniteOz,
        UniteSaisieRecolte.lb => l10n.uniteLb,
        UniteSaisieRecolte.galUs => l10n.uniteGal,
        UniteSaisieRecolte.flOz => l10n.uniteFlOz,
      };
}
