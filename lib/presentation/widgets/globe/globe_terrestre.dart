import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/dimensions_app.dart';
import 'camera_globe.dart';

/// Rotatable earth globe: drag to turn (with inertia), pinch or mouse wheel to
/// zoom, tap to pick a point.
///
/// Until the texture is ready (or if the GPU shader is unavailable) a plain
/// disc stands in, with the same gestures.
class GlobeTerrestre extends StatefulWidget {
  final CameraGlobe camera;

  /// `(latitude, longitude)` of the pin, or `null` for none.
  final (double, double)? pin;

  /// Accessible label of the globe.
  final String libelle;

  final void Function(double latitude, double longitude) onTap;

  const GlobeTerrestre({
    super.key,
    required this.camera,
    required this.libelle,
    required this.onTap,
    this.pin,
  });

  @override
  State<GlobeTerrestre> createState() => _GlobeTerrestreState();
}

class _GlobeTerrestreState extends State<GlobeTerrestre>
    with SingleTickerProviderStateMixin {
  static const String _cheminShader = 'shaders/globe.frag';
  static const String _cheminTexture = 'assets/images/globe_terre.jpg';

  /// Share of the shortest side covered by the globe at zoom 1.
  static const double _marge = 0.9;
  static const double _taillePin = TaillesIconesApp.xl;

  late final Ticker _ticker;
  Duration _dernier = Duration.zero;
  double _echellePrecedente = 1;

  ui.FragmentShader? _shader;
  ui.Image? _texture;
  bool _detruit = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.camera.addListener(_surCamera);
    unawaited(_charger());
  }

  @override
  void didUpdateWidget(GlobeTerrestre ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.camera != widget.camera) {
      ancien.camera.removeListener(_surCamera);
      widget.camera.addListener(_surCamera);
    }
  }

  @override
  void dispose() {
    _detruit = true;
    widget.camera.removeListener(_surCamera);
    _ticker.dispose();
    _shader?.dispose();
    _texture?.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final programme = await ui.FragmentProgram.fromAsset(_cheminShader);
      final donnees = await rootBundle.load(_cheminTexture);
      final codec =
          await ui.instantiateImageCodec(donnees.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      if (_detruit) {
        image.dispose();
        return;
      }
      setState(() {
        _shader = programme.fragmentShader();
        _texture = image;
      });
    } on Exception catch (e) {
      developer.log('Globe rendering unavailable, plain disc shown',
          name: 'globe', error: e);
    }
  }

  void _surCamera() {
    if (widget.camera.enMouvement && !_ticker.isActive) {
      _dernier = Duration.zero;
      _ticker.start();
    }
    setState(() {});
  }

  void _tick(Duration t) {
    final dt = _dernier == Duration.zero
        ? 0.0
        : (t - _dernier).inMicroseconds / Duration.microsecondsPerSecond;
    _dernier = t;
    // A long frame gap (app paused) must not fling the globe far away.
    if (!widget.camera.avancer(math.min(dt, 0.1))) _ticker.stop();
  }

  double _rayon(Size taille) =>
      taille.shortestSide / 2 * _marge * widget.camera.zoom;

  void _taper(Offset position, Size taille) {
    final rayon = _rayon(taille);
    final coords = widget.camera.projection
        .versCoords((position - taille.center(Offset.zero)) / rayon);
    if (coords != null) widget.onTap(coords.$1, coords.$2);
  }

  void _molette(PointerSignalEvent evenement) {
    if (evenement is PointerScrollEvent) {
      widget.camera.zoomer(math.exp(-evenement.scrollDelta.dy / 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleurRepli = Theme.of(context).colorScheme.surfaceContainerHighest;
    return LayoutBuilder(builder: (context, contraintes) {
      final taille = contraintes.biggest;
      final rayon = _rayon(taille);
      final camera = widget.camera;
      final pin = widget.pin;
      final pointPin =
          pin == null ? null : camera.projection.versDisque(pin.$1, pin.$2);
      return Semantics(
        label: widget.libelle,
        image: true,
        child: Listener(
          onPointerSignal: _molette,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (_) {
              _echellePrecedente = 1;
              camera.glisser(Offset.zero, rayon);
            },
            onScaleUpdate: (d) {
              camera.glisser(d.focalPointDelta, rayon);
              if (d.scale != _echellePrecedente) {
                camera.zoomer(d.scale / _echellePrecedente);
                _echellePrecedente = d.scale;
              }
            },
            onScaleEnd: (d) {
              camera.lacher(d.velocity.pixelsPerSecond, rayon);
              if (camera.enMouvement) _surCamera();
            },
            onTapUp: (d) => _taper(d.localPosition, taille),
            child: Stack(clipBehavior: Clip.hardEdge, children: [
              CustomPaint(
                size: taille,
                painter: _PeintreGlobe(
                  shader: _shader,
                  texture: _texture,
                  rayon: rayon,
                  latitude: camera.latitude,
                  longitude: camera.longitude,
                  couleurRepli: couleurRepli,
                ),
              ),
              if (pointPin != null)
                Positioned(
                  left: taille.width / 2 + pointPin.dx * rayon - _taillePin / 2,
                  top: taille.height / 2 + pointPin.dy * rayon - _taillePin,
                  child: IgnorePointer(
                    child: Icon(
                      PhosphorIconsBold.mapPin,
                      size: _taillePin,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
    });
  }
}

class _PeintreGlobe extends CustomPainter {
  final ui.FragmentShader? shader;
  final ui.Image? texture;
  final double rayon;
  final double latitude;
  final double longitude;
  final Color couleurRepli;

  _PeintreGlobe({
    required this.shader,
    required this.texture,
    required this.rayon,
    required this.latitude,
    required this.longitude,
    required this.couleurRepli,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = this.shader;
    final texture = this.texture;
    if (shader == null || texture == null) {
      canvas.drawCircle(
          size.center(Offset.zero), rayon, Paint()..color = couleurRepli);
      return;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, rayon)
      ..setFloat(3, longitude * math.pi / 180)
      ..setFloat(4, latitude * math.pi / 180)
      // Bilinear without mipmaps: smooth when zoomed, and no seam where the
      // texture wraps at the antimeridian.
      ..setImageSampler(0, texture, filterQuality: FilterQuality.low);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_PeintreGlobe o) =>
      o.shader != shader ||
      o.texture != texture ||
      o.rayon != rayon ||
      o.latitude != latitude ||
      o.longitude != longitude ||
      o.couleurRepli != couleurRepli;
}
