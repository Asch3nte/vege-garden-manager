import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/calculateur_dates_culture.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/stade_croissance.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

void main() {
  const calc = CalculateurDatesCulture();

  FichePlante fiche({int dureeMin = 70, int dureeMax = 90}) => FichePlante(
        id: 'tomate',
        nomScientifique: 'Solanum lycopersicum',
        familleBotanique: 'Solanaceae',
        categorie: CategoriePlante.legume,
        usages: const {UsagePlante.alimentaire},
        nomsLocalises: const {'fr': 'Tomate'},
        besoins: BesoinsCulture(
          eau: BesoinEau.eleve,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 7,
        ),
        espacementCm: 60,
        dureeAvantRecolteJoursMin: dureeMin,
        dureeAvantRecolteJoursMax: dureeMax,
        periodes: {
          Hemisphere.nord: {
            TypeClimat.oceanique: const PeriodesCulture(
              semisInterieur: Periode(2, 4),
              plantation: Periode(5, 6),
              recolte: Periode(7, 10),
            ),
          },
        },
      );

  Plantation plantation(
    DateTime dateMiseEnPlace, {
    MethodeMiseEnPlace methode = MethodeMiseEnPlace.repiquage,
  }) =>
      Plantation(
        id: 'pl1',
        planteId: 'tomate',
        parcelleId: 'par1',
        dateMiseEnPlace: dateMiseEnPlace,
        methode: methode,
        surfaceOccupee: Surface.enMetresCarres(1),
        nombrePieds: 2,
      );

  group('estimerRecolte', () {
    test('adds min/max days-to-harvest to the planting date', () {
      final est = calc.estimerRecolte(
        plantation(DateTime.utc(2026, 5, 10)),
        fiche(dureeMin: 70, dureeMax: 90),
      );
      expect(est.dateMin, DateTime.utc(2026, 7, 19)); // +70 days
      expect(est.dateMax, DateTime.utc(2026, 8, 8)); // +90 days
    });

    test('preserves the date kind and is DST-safe across month overflow', () {
      final est = calc.estimerRecolte(
        plantation(DateTime.utc(2026, 1, 20)),
        fiche(dureeMin: 15, dureeMax: 15),
      );
      expect(est.dateMin, DateTime.utc(2026, 2, 4));
      expect(est.dateMin.isUtc, isTrue);
      expect(est.dateMin, est.dateMax);
    });
  });

  group('etatCroissance', () {
    // dureeMin = 100 days → fraction thresholds fall on round day counts:
    // levée < 12 j, croissance < 66 j, maturation < 100 j, récolte ≥ 100 j.
    final f = fiche(dureeMin: 100, dureeMax: 120);
    final mep = DateTime.utc(2026, 1, 1);

    test('sowing methods pass through levée before croissance', () {
      final p = plantation(mep, methode: MethodeMiseEnPlace.semisDirect);
      // day 5 → 5% → still emerging.
      expect(
        calc.etatCroissance(p, f, DateTime.utc(2026, 1, 6)).stade,
        StadeCroissance.levee,
      );
      // day 20 → 20% → vegetative growth.
      expect(
        calc.etatCroissance(p, f, DateTime.utc(2026, 1, 21)).stade,
        StadeCroissance.croissance,
      );
    });

    test('established plants skip the levée stage (start at croissance)', () {
      final p = plantation(mep, methode: MethodeMiseEnPlace.repiquage);
      // day 5 → 5%, but a transplant is already emerged.
      expect(
        calc.etatCroissance(p, f, DateTime.utc(2026, 1, 6)).stade,
        StadeCroissance.croissance,
      );
    });

    test('crosses into maturation then récolte at the thresholds', () {
      final p = plantation(mep, methode: MethodeMiseEnPlace.repiquage);
      // day 70 → 70% → maturation.
      expect(
        calc.etatCroissance(p, f, DateTime.utc(2026, 3, 12)).stade,
        StadeCroissance.maturation,
      );
      // day 100 → 100% → harvest window reached.
      expect(
        calc.etatCroissance(p, f, DateTime.utc(2026, 4, 11)).stade,
        StadeCroissance.recolte,
      );
    });

    test('progression is the clamped elapsed/min-days-to-harvest ratio', () {
      final p = plantation(mep, methode: MethodeMiseEnPlace.repiquage);
      expect(
        calc.etatCroissance(p, f, DateTime.utc(2026, 2, 20)).progression,
        closeTo(0.50, 1e-9), // 50 days / 100
      );
      // Past the window → clamped to 1.0, still récolte.
      final tard = calc.etatCroissance(p, f, DateTime.utc(2026, 6, 1));
      expect(tard.progression, 1.0);
      expect(tard.stade, StadeCroissance.recolte);
    });

    test('a reference before planting reads as age 0 (no negative progress)', () {
      final p = plantation(mep, methode: MethodeMiseEnPlace.semisDirect);
      final etat = calc.etatCroissance(p, f, DateTime.utc(2025, 12, 20));
      expect(etat.progression, 0.0);
      expect(etat.stade, StadeCroissance.levee);
    });
  });

  group('fenetresPour', () {
    test('returns the windows for a known (hemisphere, climate) pair', () {
      final p = calc.fenetresPour(
          fiche(), Hemisphere.nord, TypeClimat.oceanique);
      expect(p, isNotNull);
      expect(p!.plantation, const Periode(5, 6));
      expect(p.recolte, const Periode(7, 10));
    });

    test('returns null for an unknown pair', () {
      expect(
        calc.fenetresPour(fiche(), Hemisphere.sud, TypeClimat.oceanique),
        isNull,
      );
    });
  });

  group('hemisphereDe', () {
    test('north for non-negative latitude', () {
      final loc = Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);
      expect(calc.hemisphereDe(loc), Hemisphere.nord);
    });

    test('south for negative latitude', () {
      final loc = Localisation.gps(latitude: -33.86, longitude: 151.2);
      expect(calc.hemisphereDe(loc), Hemisphere.sud);
    });

    test('null when latitude is unknown (no silent default)', () {
      expect(calc.hemisphereDe(const Localisation.nonDefinie()), isNull);
    });
  });
}
