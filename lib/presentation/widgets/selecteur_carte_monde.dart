import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/service_providers.dart';
import '../../application/state/preferences_notifier.dart';
import '../../domain/exceptions/geocodage_indisponible_exception.dart';
import '../../domain/value_objects/lieu_trouve.dart';
import '../../domain/value_objects/localisation.dart';
import '../../l10n/app_localizations.dart';
import 'globe/camera_globe.dart';
import 'globe/globe_terrestre.dart';
import 'libelle_position.dart';

/// Opens the globe position picker and returns the chosen [Localisation]
/// (manual source), or `null` if the user cancelled.
Future<Localisation?> choisirSurCarteMonde(BuildContext context) {
  return Navigator.of(context).push<Localisation>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _EcranCarteMonde(),
    ),
  );
}

class _EcranCarteMonde extends ConsumerStatefulWidget {
  const _EcranCarteMonde();

  @override
  ConsumerState<_EcranCarteMonde> createState() => _EcranCarteMondeState();
}

enum _EtatRecherche { inactive, enCours, aucune, indisponible }

class _EcranCarteMondeState extends ConsumerState<_EcranCarteMonde> {
  static const double _zoomLieu = 6;

  /// Waits for taps to calm down before naming the point, so a burst of taps
  /// sends a single lookup.
  static const Duration _delaiNommage = Duration(milliseconds: 500);

  final CameraGlobe _camera = CameraGlobe(latitude: 30, longitude: 10);
  final TextEditingController _champ = TextEditingController();

  (double, double)? _point;
  LieuTrouve? _lieu;
  bool _nommage = false;
  Timer? _minuterieNommage;

  // Bumped so late answers are ignored: one counter per kind of request.
  int _jetonRecherche = 0;
  int _jetonPoint = 0;

  /// Whether the tapped point is named automatically; off with the automatic
  /// network opt-out.
  bool _nommageAuto = false;

  _EtatRecherche _recherche = _EtatRecherche.inactive;
  List<LieuTrouve> _suggestions = const [];

  @override
  void dispose() {
    _minuterieNommage?.cancel();
    _camera.dispose();
    _champ.dispose();
    super.dispose();
  }

  Future<void> _rechercher(String texte) async {
    if (texte.trim().isEmpty) return;
    final jeton = ++_jetonRecherche;
    setState(() {
      _recherche = _EtatRecherche.enCours;
      _suggestions = const [];
    });
    final List<LieuTrouve> lieux;
    try {
      lieux = await ref.read(geocodageServiceProvider).rechercherLieux(texte);
    } on GeocodageIndisponibleException {
      if (mounted && jeton == _jetonRecherche) {
        setState(() => _recherche = _EtatRecherche.indisponible);
      }
      return;
    }
    if (!mounted || jeton != _jetonRecherche) return;
    if (lieux.length == 1) {
      _choisirLieu(lieux.single);
      return;
    }
    setState(() {
      _suggestions = lieux;
      _recherche =
          lieux.isEmpty ? _EtatRecherche.aucune : _EtatRecherche.inactive;
    });
  }

  void _choisirLieu(LieuTrouve lieu) {
    _jetonRecherche++;
    _jetonPoint++;
    _minuterieNommage?.cancel();
    FocusScope.of(context).unfocus();
    _camera.viser(lieu.latitude, lieu.longitude, zoom: _zoomLieu);
    setState(() {
      _point = (lieu.latitude, lieu.longitude);
      _lieu = lieu;
      _nommage = false;
      _suggestions = const [];
      _recherche = _EtatRecherche.inactive;
    });
  }

  void _poser(double latitude, double longitude) {
    final jeton = ++_jetonPoint;
    _minuterieNommage?.cancel();
    setState(() {
      _point = (latitude, longitude);
      _lieu = null;
      _nommage = _nommageAuto;
      _suggestions = const [];
      _recherche = _EtatRecherche.inactive;
    });
    if (!_nommageAuto) return;
    _minuterieNommage = Timer(_delaiNommage, () async {
      final lieu = await ref
          .read(geocodageServiceProvider)
          .identifierLieu(latitude, longitude);
      if (!mounted || jeton != _jetonPoint) return;
      setState(() {
        _lieu = lieu;
        _nommage = false;
      });
    });
  }

  void _effacer() {
    _champ.clear();
    _jetonRecherche++;
    setState(() {
      _suggestions = const [];
      _recherche = _EtatRecherche.inactive;
    });
  }

  void _valider() {
    final point = _point;
    if (point == null) return;
    _minuterieNommage?.cancel();
    _jetonPoint++;
    final (lat, lon) = point;
    Navigator.of(context).pop(Localisation.manuelle(
      ville: _lieu?.nom ?? LibellePosition.coordonnees(lat, lon),
      latitude: lat,
      longitude: lon,
    ));
  }

  static String? _contexte(LieuTrouve lieu) {
    final parties = [lieu.region, lieu.pays].whereType<String>();
    return parties.isEmpty ? null : parties.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    _nommageAuto =
        ref.watch(preferencesProvider).value?.meteoAutoActive ?? false;

    final message = switch (_recherche) {
      _EtatRecherche.aucune => l10n.carteMondeRechercheAucune,
      _EtatRecherche.indisponible => l10n.carteMondeRechercheIndisponible,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.carteMondeTitre)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(EspacementsApp.s4,
                  EspacementsApp.s4, EspacementsApp.s4, EspacementsApp.s2),
              child: TextField(
                controller: _champ,
                textInputAction: TextInputAction.search,
                onSubmitted: _rechercher,
                decoration: InputDecoration(
                  hintText: l10n.carteMondeRechercheIndice,
                  prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
                  suffixIcon: _recherche == _EtatRecherche.enCours
                      ? const Padding(
                          padding: EdgeInsets.all(EspacementsApp.s3),
                          child: SizedBox.square(
                            dimension: TaillesIconesApp.sm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: l10n.carteMondeRechercheEffacer,
                          icon: const Icon(PhosphorIconsRegular.x),
                          onPressed: _effacer,
                        ),
                  helperText: message ?? l10n.carteMondeInstruction,
                  helperMaxLines: 2,
                  helperStyle: message == null
                      ? null
                      : TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GlobeTerrestre(
                      camera: _camera,
                      pin: _point,
                      libelle: l10n.carteMondeGlobe,
                      onTap: _poser,
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Positioned(
                      left: EspacementsApp.s4,
                      right: EspacementsApp.s4,
                      top: 0,
                      bottom: EspacementsApp.s4,
                      child: _ListeSuggestions(
                        lieux: _suggestions,
                        contexte: _contexte,
                        onChoix: _choisirLieu,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EspacementsApp.s4),
              child: Row(
                children: [
                  Expanded(child: _piedLieu(l10n, theme)),
                  const SizedBox(width: EspacementsApp.s3),
                  FilledButton(
                    onPressed: _point == null ? null : _valider,
                    child: Text(l10n.carteMondeValider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Name and whereabouts of the chosen point, left of the confirm button.
  Widget _piedLieu(AppLocalizations l10n, ThemeData theme) {
    final secondaire = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final point = _point;
    if (point == null) {
      return Text(l10n.carteMondeAucunePosition, style: secondaire);
    }
    final coords = LibellePosition.coordonnees(point.$1, point.$2);
    final lieu = _lieu;
    final titre = lieu?.nom ?? (_nommage ? l10n.carteMondeNomEnCours : coords);
    final contexte = lieu == null ? null : _contexte(lieu);
    final detail = lieu == null
        ? (_nommage ? coords : null)
        : [?contexte, coords].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titre,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (detail != null)
          Text(detail,
              style: secondaire, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// Matches of a place search, each with its region and country.
class _ListeSuggestions extends StatelessWidget {
  final List<LieuTrouve> lieux;
  final String? Function(LieuTrouve) contexte;
  final ValueChanged<LieuTrouve> onChoix;

  const _ListeSuggestions({
    required this.lieux,
    required this.contexte,
    required this.onChoix,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        elevation: 3,
        borderRadius: RayonsApp.brMd,
        clipBehavior: Clip.antiAlias,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            for (final lieu in lieux)
              ListTile(
                leading: const Icon(PhosphorIconsRegular.mapPin),
                title: Text(lieu.nom),
                subtitle: switch (contexte(lieu)) {
                  final c? => Text(c),
                  null => null,
                },
                onTap: () => onChoix(lieu),
              ),
          ],
        ),
      ),
    );
  }
}
