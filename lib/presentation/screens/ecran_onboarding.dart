import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/engine/derivateur_localisation.dart';
import '../../application/providers/service_providers.dart';
import '../../application/state/potagers_notifier.dart';
import '../../application/state/preferences_notifier.dart';
import '../../domain/enums/mode_geolocalisation.dart';
import '../../domain/enums/source_localisation.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/capture_localisation.dart';
import '../widgets/champ_deroulant_decrit.dart';
import '../widgets/libelles_enums.dart';
import '../widgets/selecteur_carte_monde.dart';

/// First-launch onboarding flow (guided, multi-step).
///
/// Shown full-screen (outside the navigation shell) while
/// [PreferencesUtilisateur.onboardingTermine] is `false`; the router redirects
/// here until the user completes it. Steps: welcome → privacy → position
/// (required) → derived climate/hardiness (editable) → first garden →
/// notifications opt-in. Finishing creates the first garden (with the captured
/// position and climate), records the geolocation mode and notification choice,
/// and lifts the router gate.
class EcranOnboarding extends ConsumerStatefulWidget {
  const EcranOnboarding({super.key});

  @override
  ConsumerState<EcranOnboarding> createState() => _EcranOnboardingState();
}

class _EcranOnboardingState extends ConsumerState<EcranOnboarding> {
  final PageController _pages = PageController();
  final TextEditingController _nom = TextEditingController();

  int _etape = 0;
  Localisation _position = const Localisation.nonDefinie();
  TypeClimat _climat = TypeClimat.oceanique;
  ZoneRusticite _rusticite = ZoneRusticite.zone8;
  bool _notifications = true;
  bool _enregistrement = false;

  @override
  void dispose() {
    _pages.dispose();
    _nom.dispose();
    super.dispose();
  }

  /// Stores [position] and pre-fills climate & hardiness from its derivation.
  void _appliquerPosition(Localisation position) {
    if (!position.estDefinie) return;
    final suggestion = const DerivateurLocalisation().deriver(position);
    setState(() {
      _position = position;
      _climat = suggestion.climat;
      _rusticite = suggestion.rusticite;
    });
  }

  Future<void> _detecterGps() async {
    final loc = await capterGps(context, ref.read(geolocalisationServiceProvider));
    if (loc != null) _appliquerPosition(loc);
  }

  Future<void> _choisirSurCarte() async {
    final loc = await choisirSurCarteMonde(context);
    if (loc != null) _appliquerPosition(loc);
  }

  Future<void> _terminer() async {
    setState(() => _enregistrement = true);
    final prefs = ref.read(preferencesProvider.notifier);
    try {
      await ref.read(potagersProvider.notifier).creer(
            nom: _nom.text.trim(),
            zoneClimatique: ZoneClimatique(_climat, _rusticite),
            localisation: _position,
          );
      // Reflect the captured position's origin so the privacy panel is coherent.
      await prefs.definirGeolocalisation(
        _position.source == SourceLocalisation.gps
            ? ModeGeolocalisation.gps
            : ModeGeolocalisation.manuelle,
      );
      await prefs.definirNotificationsGlobales(_notifications);
      // Lifts the router gate (refreshListenable → redirect to Accueil).
      await prefs.terminerOnboarding();
    } catch (_) {
      if (mounted) {
        setState(() => _enregistrement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.onboardingErreur)),
        );
      }
    }
  }

  void _suivant() {
    if (_etape >= _nombreEtapes - 1) {
      _terminer();
      return;
    }
    setState(() => _etape++);
    _pages.animateToPage(
      _etape,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _precedent() {
    if (_etape == 0) return;
    setState(() => _etape--);
    _pages.animateToPage(
      _etape,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  static const int _nombreEtapes = 6;

  /// Whether the current step's requirements are met (gates the Next button):
  /// the position must be set (step 2) and the garden must be named (step 4).
  bool get _peutAvancer {
    switch (_etape) {
      case 2:
        return _position.estDefinie;
      case 4:
        return _nom.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dernier = _etape == _nombreEtapes - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _EtapeSimple(
                    icone: Icons.eco_outlined,
                    titre: l10n.onboardingBienvenueTitre,
                    corps: l10n.onboardingBienvenueCorps,
                  ),
                  _EtapeSimple(
                    icone: Icons.lock_outline,
                    titre: l10n.onboardingViePriveeTitre,
                    corps: l10n.onboardingViePriveeCorps,
                  ),
                  _etapePosition(l10n),
                  _etapeClimat(l10n),
                  _etapePotager(l10n),
                  _etapeNotifications(l10n),
                ],
              ),
            ),
            _Indicateur(etape: _etape, total: _nombreEtapes),
            Padding(
              padding: const EdgeInsets.all(EspacementsApp.s4),
              child: Row(
                children: [
                  if (_etape > 0)
                    TextButton(
                      onPressed: _enregistrement ? null : _precedent,
                      child: Text(l10n.onboardingPrecedent),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed:
                        (!_peutAvancer || _enregistrement) ? null : _suivant,
                    child: _enregistrement
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(dernier
                            ? l10n.onboardingTerminer
                            : (_etape == 0
                                ? l10n.onboardingCommencer
                                : l10n.onboardingSuivant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etapePosition(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return _Etape(
      icone: Icons.place_outlined,
      titre: l10n.onboardingPositionTitre,
      corps: l10n.onboardingPositionCorps,
      enfants: [
        OutlinedButton.icon(
          onPressed: _detecterGps,
          icon: const Icon(Icons.my_location),
          label: Text(l10n.formPotagerDetecter),
        ),
        const SizedBox(height: EspacementsApp.s2),
        OutlinedButton.icon(
          onPressed: _choisirSurCarte,
          icon: const Icon(Icons.public_outlined),
          label: Text(l10n.captureCarteChoisir),
        ),
        if (_position.estDefinie)
          Padding(
            padding: const EdgeInsets.only(top: EspacementsApp.s3),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: TaillesIconesApp.md, color: theme.colorScheme.primary),
                const SizedBox(width: EspacementsApp.s2),
                Expanded(
                  child: Text(l10n.onboardingPositionDefinie,
                      style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _etapeClimat(AppLocalizations l10n) {
    return _Etape(
      icone: Icons.thermostat_outlined,
      titre: l10n.onboardingClimatTitre,
      corps: l10n.onboardingClimatCorps,
      enfants: [
        ChampDeroulantDecrit<TypeClimat>(
          value: _climat,
          options: TypeClimat.values,
          libelle: l10n.climat,
          description: l10n.climatDescription,
          labelText: l10n.formPotagerClimat,
          onChanged: (v) => setState(() => _climat = v),
        ),
        const SizedBox(height: EspacementsApp.s4),
        ChampDeroulantDecrit<ZoneRusticite>(
          value: _rusticite,
          options: ZoneRusticite.values,
          libelle: l10n.rusticite,
          description: l10n.rusticiteDescription,
          labelText: l10n.formPotagerRusticite,
          onChanged: (v) => setState(() => _rusticite = v),
        ),
      ],
    );
  }

  Widget _etapePotager(AppLocalizations l10n) {
    return _Etape(
      icone: Icons.yard_outlined,
      titre: l10n.onboardingPotagerTitre,
      corps: l10n.onboardingPotagerCorps,
      enfants: [
        TextField(
          controller: _nom,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.formPotagerNom,
            border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
          ),
          // Drive the Next button's enabled state from the field content.
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _etapeNotifications(AppLocalizations l10n) {
    return _Etape(
      icone: Icons.notifications_outlined,
      titre: l10n.onboardingNotifsTitre,
      corps: l10n.onboardingNotifsCorps,
      enfants: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.onboardingNotifsActiver),
          value: _notifications,
          onChanged: (v) => setState(() => _notifications = v),
        ),
      ],
    );
  }
}

/// A scrollable onboarding step: an icon, a title, a body, and optional content.
class _Etape extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String corps;
  final List<Widget> enfants;

  const _Etape({
    required this.icone,
    required this.titre,
    required this.corps,
    this.enfants = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(EspacementsApp.s6),
      children: [
        Icon(icone, size: TaillesIconesApp.xl2, color: theme.colorScheme.primary),
        const SizedBox(height: EspacementsApp.s5),
        Text(titre, style: theme.textTheme.headlineSmall),
        const SizedBox(height: EspacementsApp.s3),
        Text(
          corps,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (enfants.isNotEmpty) const SizedBox(height: EspacementsApp.s6),
        ...enfants,
      ],
    );
  }
}

/// A centered informational step (welcome / privacy), no interactive content.
class _EtapeSimple extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String corps;

  const _EtapeSimple({
    required this.icone,
    required this.titre,
    required this.corps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EspacementsApp.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone,
              size: TaillesIconesApp.xl2, color: theme.colorScheme.primary),
          const SizedBox(height: EspacementsApp.s6),
          Text(titre,
              style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: EspacementsApp.s4),
          Text(
            corps,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Row of dots showing progress across the onboarding steps.
class _Indicateur extends StatelessWidget {
  final int etape;
  final int total;

  const _Indicateur({required this.etape, required this.total});

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: EspacementsApp.s1),
            width: i == etape ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == etape ? couleur : couleur.withValues(alpha: 0.3),
              borderRadius: RayonsApp.brSm,
            ),
          ),
      ],
    );
  }
}
