import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/engine/derivateur_localisation.dart';
import '../../application/providers/service_providers.dart';
import '../../application/state/potagers_notifier.dart';
import '../../application/state/preferences_notifier.dart';
import '../../domain/enums/mode_geolocalisation.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/source_localisation.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_zone.dart';
import '../widgets/astuce_post_onboarding.dart';
import '../widgets/capture_localisation.dart';
import '../widgets/champ_deroulant_decrit.dart';
import '../widgets/invalidation_vues.dart';
import '../widgets/libelles_enums.dart';
import '../widgets/selecteur_carte_monde.dart';

/// First-launch onboarding flow (guided, multi-step).
///
/// Shown full-screen (outside the navigation shell) while
/// [PreferencesUtilisateur.onboardingTermine] is `false`; the router redirects
/// here until the user completes it. Steps: welcome → privacy → position
/// (required, auto-advances) → derived climate/hardiness → experience level
/// (ADR-0009) → first garden (name + zones) → notifications opt-in. The garden
/// is created lazily (as soon as a zone is added, or when leaving the garden
/// step), so zones can attach to it. Finishing records the level, geolocation
/// mode and notification choice, refreshes the data views and lifts the router
/// gate (which then lands on the Potager screen).
class EcranOnboarding extends ConsumerStatefulWidget {
  const EcranOnboarding({super.key});

  @override
  ConsumerState<EcranOnboarding> createState() => _EcranOnboardingState();
}

class _EcranOnboardingState extends ConsumerState<EcranOnboarding> {
  final PageController _pages = PageController();
  final TextEditingController _nom = TextEditingController();

  // Step indices.
  static const int _etapePositionIndex = 2;
  static const int _etapePotagerIndex = 5;
  static const int _nombreEtapes = 7;

  int _etape = 0;
  Localisation _position = const Localisation.nonDefinie();
  TypeClimat _climat = TypeClimat.oceanique;
  ZoneRusticite _rusticite = ZoneRusticite.zone8;
  NiveauExperience _niveau = NiveauExperience.debutant;
  bool _notifications = true;
  bool _enregistrement = false;

  /// Id of the first garden, once created lazily (null until then).
  String? _potagerId;
  int _zonesAjoutees = 0;

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
    final loc =
        await capterGps(context, ref.read(geolocalisationServiceProvider));
    if (loc != null) {
      _appliquerPosition(loc);
      _avancerDepuisPosition();
    }
  }

  Future<void> _choisirSurCarte() async {
    final loc = await choisirSurCarteMonde(context);
    if (loc != null) {
      _appliquerPosition(loc);
      _avancerDepuisPosition();
    }
  }

  /// Once a position is captured, move straight to the next step (no extra
  /// "Suivant" tap — test feedback #1).
  void _avancerDepuisPosition() {
    if (mounted && _etape == _etapePositionIndex && _position.estDefinie) {
      _suivant();
    }
  }

  /// Creates the first garden if not already created, and returns its id.
  /// Idempotent: called when adding a zone and when leaving the garden step.
  Future<String> _assurerPotager() async {
    final existant = _potagerId;
    if (existant != null) return existant;
    final potager = await ref.read(potagersProvider.notifier).creer(
          nom: _nom.text.trim(),
          zoneClimatique: ZoneClimatique(_climat, _rusticite),
          localisation: _position,
        );
    _potagerId = potager.id;
    return potager.id;
  }

  Future<void> _ajouterZone() async {
    setState(() => _enregistrement = true);
    String id;
    try {
      id = await _assurerPotager();
    } catch (_) {
      _signalerErreur();
      return;
    }
    if (mounted) setState(() => _enregistrement = false);
    if (!mounted) return;
    final zone = await ouvrirFormulaireZone(context, id);
    if (zone != null && mounted) setState(() => _zonesAjoutees++);
  }

  void _signalerErreur() {
    if (!mounted) return;
    setState(() => _enregistrement = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.onboardingErreur)),
    );
  }

  Future<void> _terminer() async {
    setState(() => _enregistrement = true);
    final prefs = ref.read(preferencesProvider.notifier);
    try {
      await _assurerPotager(); // idempotent — created already if a zone was added
      await prefs.definirNiveau(_niveau);
      // Reflect the captured position's origin so the privacy panel is coherent.
      await prefs.definirGeolocalisation(
        _position.source == SourceLocalisation.gps
            ? ModeGeolocalisation.gps
            : ModeGeolocalisation.manuelle,
      );
      await prefs.definirNotificationsGlobales(_notifications);
      // Refresh the data views so the (otherwise cached) dashboard/potager show
      // the freshly created garden — test feedback #5.
      invaliderVuesDonnees(ref);
      // One-off hint shown on the Potager screen we land on (feedback #4).
      ref.read(astucePotagerZonesProvider.notifier).afficher();
      // Lifts the router gate (refreshListenable → redirect to Potager).
      await prefs.terminerOnboarding();
    } catch (_) {
      _signalerErreur();
    }
  }

  Future<void> _suivant() async {
    if (_enregistrement) return;
    // Ensure the garden exists before leaving the garden step (so finishing
    // doesn't double-create and the notifications step is the last action).
    if (_etape == _etapePotagerIndex) {
      setState(() => _enregistrement = true);
      try {
        await _assurerPotager();
      } catch (_) {
        _signalerErreur();
        return;
      }
      if (!mounted) return;
      setState(() => _enregistrement = false);
    }
    if (_etape >= _nombreEtapes - 1) {
      await _terminer();
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

  /// Whether the current step's requirements are met (gates the Next button):
  /// the position must be set, and the garden must be named.
  bool get _peutAvancer {
    switch (_etape) {
      case _etapePositionIndex:
        return _position.estDefinie;
      case _etapePotagerIndex:
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
                  _etapeNiveau(l10n),
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

  Widget _etapeNiveau(AppLocalizations l10n) {
    return _Etape(
      icone: Icons.school_outlined,
      titre: l10n.onboardingNiveauTitre,
      corps: l10n.onboardingNiveauCorps,
      enfants: [
        for (final n in NiveauExperience.values) ...[
          _CarteNiveau(
            titre: l10n.niveauExperience(n),
            description: l10n.niveauDescription(n),
            selectionne: _niveau == n,
            onTap: () => setState(() => _niveau = n),
          ),
          const SizedBox(height: EspacementsApp.s3),
        ],
      ],
    );
  }

  Widget _etapePotager(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final cree = _potagerId != null;
    return _Etape(
      icone: Icons.yard_outlined,
      titre: l10n.onboardingPotagerTitre,
      corps: l10n.onboardingPotagerCorps,
      enfants: [
        TextField(
          controller: _nom,
          autofocus: true,
          enabled: !cree, // locked once the garden is created (a zone was added)
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.formPotagerNom,
            border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
          ),
          onChanged: (_) => setState(() {}), // gate the Next button
        ),
        const SizedBox(height: EspacementsApp.s6),
        Text(l10n.onboardingPotagerZonesTitre, style: theme.textTheme.titleMedium),
        const SizedBox(height: EspacementsApp.s2),
        Text(
          l10n.onboardingPotagerZonesCorps,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: EspacementsApp.s3),
        OutlinedButton.icon(
          // Needs a garden name first (the zone attaches to the lazily-created
          // garden).
          onPressed: (_nom.text.trim().isEmpty || _enregistrement)
              ? null
              : _ajouterZone,
          icon: const Icon(Icons.add),
          label: Text(l10n.onboardingPotagerAjouterZone),
        ),
        const SizedBox(height: EspacementsApp.s2),
        Text(
          l10n.onboardingPotagerZonesCompte(_zonesAjoutees),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

/// A selectable experience-level card (label + one-line description).
class _CarteNiveau extends StatelessWidget {
  final String titre;
  final String description;
  final bool selectionne;
  final VoidCallback onTap;

  const _CarteNiveau({
    required this.titre,
    required this.description,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          decoration: BoxDecoration(
            color: selectionne
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.all(RayonsApp.lg),
            border: Border.all(
              color: selectionne
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selectionne ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selectionne
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selectionne
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: TaillesIconesApp.md,
              ),
              const SizedBox(width: EspacementsApp.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: theme.textTheme.titleMedium),
                    const SizedBox(height: EspacementsApp.s1),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
