import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../../domain/value_objects/localisation.dart';
import '../../l10n/app_localizations.dart';

/// Approximate world regions used as quick-jump shortcuts on the map: each maps
/// to representative coordinates. Shared so the list lives in one place.
List<(String, double, double)> regionsLocalisation(AppLocalizations l10n) => [
      (l10n.regionEuropeOuest, 48, 2),
      (l10n.regionMediterranee, 38, 12),
      (l10n.regionEuropeNord, 60, 18),
      (l10n.regionTropiques, 5, 25),
      (l10n.regionAmeriqueNord, 42, -90),
      (l10n.regionHemisphereSud, -33, 18),
    ];

/// Linear plate-carrée (equirectangular) projection between a point's
/// **fractional position** on the world map image and its **geographic
/// coordinates**.
///
/// The embedded map (`assets/images/carte_monde.jpg`, NASA Blue Marble, public
/// domain) is a full-globe equirectangular image: the horizontal axis maps
/// linearly to longitude `[-180, +180]` (left → right) and the vertical axis to
/// latitude `[+90, -90]` (top → bottom). Pure and side-effect-free so the
/// mapping can be unit-tested without a widget tree.
class ProjectionEquirectangulaire {
  const ProjectionEquirectangulaire._();

  /// Geographic `(latitude, longitude)` for a fractional position `(fx, fy)`,
  /// each in `[0, 1]` (clamped). `(0,0)` is the top-left (−180°, +90°).
  static (double latitude, double longitude) versCoords(double fx, double fy) {
    final x = fx.clamp(0.0, 1.0);
    final y = fy.clamp(0.0, 1.0);
    return (90 - y * 180, x * 360 - 180);
  }

  /// Fractional position `(fx, fy)` in `[0, 1]` for geographic coordinates.
  static (double fx, double fy) versFraction(double latitude, double longitude) {
    final fx = ((longitude + 180) / 360).clamp(0.0, 1.0);
    final fy = ((90 - latitude) / 180).clamp(0.0, 1.0);
    return (fx, fy);
  }
}

/// Opens the zoomable world-map picker and returns the chosen [Localisation]
/// (manual source), or `null` if the user cancelled. The map replaces the older
/// coarse region list: the user pans/zooms to pick the precision they want.
Future<Localisation?> choisirSurCarteMonde(BuildContext context) {
  return Navigator.of(context).push<Localisation>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _EcranCarteMonde(),
    ),
  );
}

class _EcranCarteMonde extends StatefulWidget {
  const _EcranCarteMonde();

  @override
  State<_EcranCarteMonde> createState() => _EcranCarteMondeState();
}

class _EcranCarteMondeState extends State<_EcranCarteMonde> {
  /// Asset aspect ratio (2058 × 1036 px) — kept exact so the full image spans
  /// the full lon/lat range without distortion under `BoxFit.fill`.
  static const double _ratioCarte = 2058 / 1036;
  static const String _chemin = 'assets/images/carte_monde.jpg';
  static const double _zoomMax = 14;
  static const double _zoomPreset = 4;

  final TransformationController _tc = TransformationController();

  /// Selected point as a fractional position on the map, or `null` if none yet.
  Offset? _fraction;

  /// Interactive viewport size and the image's box within it (the map is
  /// contained, keeping its 2:1 ratio, so the zoom/pan canvas fills the whole
  /// available space while the image stays proportional). Captured in [build]
  /// so presets/pin can convert between image space and the viewport.
  Size? _viewport;
  Rect _imageRect = Rect.zero;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _poser(Offset positionLocale, Size taille) {
    setState(() {
      _fraction = Offset(
        (positionLocale.dx / taille.width).clamp(0.0, 1.0),
        (positionLocale.dy / taille.height).clamp(0.0, 1.0),
      );
    });
  }

  /// Maps a fractional map position to a point in the InteractiveViewer child's
  /// coordinate space (the viewport-sized canvas at scale 1).
  Offset _pointCanevas(Offset fraction) => Offset(
        _imageRect.left + fraction.dx * _imageRect.width,
        _imageRect.top + fraction.dy * _imageRect.height,
      );

  /// Centres the view on [fraction] at a moderate zoom (region presets) and
  /// drops the pin there.
  void _allerVers(Offset fraction) {
    final v = _viewport;
    if (v == null) return;
    final s = _zoomPreset;
    final p = _pointCanevas(fraction);
    _tc.value = Matrix4.identity()
      ..translateByDouble(v.width / 2 - s * p.dx, v.height / 2 - s * p.dy, 0, 1)
      ..scaleByDouble(s, s, s, 1);
    setState(() => _fraction = fraction);
  }

  void _valider() {
    final f = _fraction;
    if (f == null) return;
    final (lat, lon) = ProjectionEquirectangulaire.versCoords(f.dx, f.dy);
    Navigator.of(context).pop(
      Localisation.manuelle(ville: _libelleCoords(lat, lon), latitude: lat, longitude: lon),
    );
  }

  /// Compact human-readable coordinate label (e.g. `48.2° N, 2.4° E`). The
  /// cardinal letters are geographic notation, intentionally kept literal.
  String _libelleCoords(double lat, double lon) {
    final ns = lat >= 0 ? 'N' : 'S';
    final eo = lon >= 0 ? 'E' : 'O';
    return '${lat.abs().toStringAsFixed(1)}° $ns, '
        '${lon.abs().toStringAsFixed(1)}° $eo';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.carteMondeTitre),
        actions: [
          TextButton(
            onPressed: _fraction == null ? null : _valider,
            child: Text(l10n.carteMondeValider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EspacementsApp.s4),
            child: Text(
              l10n.carteMondeInstruction,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          // The interactive zone fills all the available vertical space: the
          // zoom/pan canvas spans the whole area (so zooming uses every pixel
          // up to these bounds), while the 2:1 image stays contained inside it.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final vw = constraints.maxWidth;
                final vh = constraints.maxHeight;
                // Contain the map keeping its ratio: fit by width unless that
                // overflows the height, then fit by height.
                var imgW = vw;
                var imgH = vw / _ratioCarte;
                if (imgH > vh) {
                  imgH = vh;
                  imgW = vh * _ratioCarte;
                }
                final rect = Rect.fromLTWH(
                    (vw - imgW) / 2, (vh - imgH) / 2, imgW, imgH);
                _viewport = Size(vw, vh);
                _imageRect = rect;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _tc,
                        minScale: 1,
                        maxScale: _zoomMax,
                        child: SizedBox(
                          width: vw,
                          height: vh,
                          child: Stack(
                            children: [
                              Positioned.fromRect(
                                rect: rect,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (d) =>
                                      _poser(d.localPosition, rect.size),
                                  child:
                                      Image.asset(_chemin, fit: BoxFit.fill),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Pin overlay: re-projected through the live transform, at
                    // constant screen size (it does not zoom with the map).
                    if (_fraction != null)
                      AnimatedBuilder(
                        animation: _tc,
                        builder: (context, _) => _pin(),
                      ),
                  ],
                );
              },
            ),
          ),
          _BandeRegions(
            onRegion: (lat, lon) {
              final (fx, fy) =
                  ProjectionEquirectangulaire.versFraction(lat, lon);
              _allerVers(Offset(fx, fy));
            },
            regions: regionsLocalisation(l10n),
          ),
        ],
      ),
    );
  }

  Widget _pin() {
    final p = MatrixUtils.transformPoint(_tc.value, _pointCanevas(_fraction!));
    const double largeur = 32;
    const double hauteur = 36;
    return Positioned(
      left: p.dx - largeur / 2,
      top: p.dy - hauteur,
      width: largeur,
      height: hauteur,
      child: IgnorePointer(
        child: Icon(
          Icons.location_on,
          size: hauteur,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

/// Horizontal band of region shortcuts: tapping one jumps the map to that
/// region (and drops the pin there) so the user can then refine by zooming.
class _BandeRegions extends StatelessWidget {
  final List<(String, double, double)> regions;
  final void Function(double lat, double lon) onRegion;

  const _BandeRegions({required this.regions, required this.onRegion});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s3),
        children: [
          for (final (label, lat, lon) in regions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s1),
              child: Center(
                child: ActionChip(
                  avatar: const Icon(Icons.public_outlined,
                      size: TaillesIconesApp.sm),
                  label: Text(label),
                  onPressed: () => onRegion(lat, lon),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
