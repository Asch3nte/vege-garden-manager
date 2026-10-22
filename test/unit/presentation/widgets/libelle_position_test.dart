import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/libelle_position.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  test('formats coordinates in the locale', () {
    expect(LibellePosition.coordonnees(l10n, 50.04, 4.71), '50,0° N, 4,7° E');
    expect(LibellePosition.coordonnees(l10n, -33.9, -70.66),
        '33,9° S, 70,7° O');
    expect(
        LibellePosition.coordonnees(
            lookupAppLocalizations(const Locale('en')), -33.9, -70.66),
        '33.9° S, 70.7° W');
  });

  test('a value rounding to zero is not shown as south or west', () {
    expect(LibellePosition.coordonnees(l10n, -0.04, -0.03), '0,0° N, 0,0° E');
    expect(LibellePosition.libelleStocke(-0.04, -0.03), '0.0° N, 0.0° E');
  });

  test('the stored label is locale-neutral', () {
    expect(LibellePosition.libelleStocke(-33.9, -70.66), '33.9° S, 70.7° O');
  });

  test('a manual position shows its place and that it was chosen by hand', () {
    final p = LibellePosition(
        Localisation.manuelle(ville: 'Haybes', latitude: 50, longitude: 4.71),
        l10n);
    expect(p.titre, 'Haybes');
    expect(p.detail, 'Choisie sur le globe · 50,0° N, 4,7° E');
    expect(p.court, 'Haybes · globe');
    expect(p.icone, PhosphorIconsRegular.globe);
  });

  test('an unnamed manual position shows its stored coordinates once', () {
    // The label was built before rounding: 4.749 → '4.7', stored as 4.75.
    final p = LibellePosition(
        Localisation.manuelle(
            ville: '50.0° N, 4.7° E', latitude: 50, longitude: 4.749),
        l10n);
    expect(p.titre, '50,0° N, 4,8° E');
    expect(p.detail, 'Choisie sur le globe');
    expect(p.court, '50,0° N, 4,8° E · globe');
  });

  test('a GPS position says so and shows its coordinates', () {
    final p = LibellePosition(
        Localisation.gps(latitude: 50.61, longitude: 5.42), l10n);
    expect(p.titre, 'Position GPS');
    expect(p.detail, '50,6° N, 5,4° E');
    expect(p.court, 'GPS · 50,6° N, 5,4° E');
    expect(p.icone, PhosphorIconsRegular.crosshair);
  });

  test('no position has no detail', () {
    final p = LibellePosition(const Localisation.nonDefinie(), l10n);
    expect(p.titre, 'Aucune position');
    expect(p.detail, isNull);
    expect(p.court, 'Aucune position');
  });
}
