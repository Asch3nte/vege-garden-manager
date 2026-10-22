import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/sens_swipe_provider.dart';
import '../../domain/enums/sens_swipe.dart';
import '../../l10n/app_localizations.dart';

/// A swipe action; resolves to whether the item leaves its list.
typedef ActionBalayage = Future<bool> Function();

/// A list item swiped to delete or archive, sides set by [sensSwipeProvider].
///
/// Standard: towards the start deletes, towards the end archives. Both actions
/// stay reachable from the item's menu and as screen-reader actions.
class ElementBalayable extends ConsumerStatefulWidget {
  /// Identity of the item within its list.
  final String cle;

  /// Archiving action (done, pulled out, removed…); none leaves the side inert.
  final ActionBalayage? surArchiver;

  /// Screen-reader label of [surArchiver].
  final String? libelleArchiver;

  /// Deleting action, confirmation included; none leaves the side inert.
  final ActionBalayage? surSupprimer;

  /// Corners of the item, so the revealed strip follows its shape.
  final BorderRadius? arrondi;

  final Widget child;

  ElementBalayable({
    required this.cle,
    required this.child,
    this.surArchiver,
    this.libelleArchiver,
    this.surSupprimer,
    this.arrondi,
  })  : assert(surArchiver == null || libelleArchiver != null,
            'an archiving action needs its label'),
        // Keyed so a removed item's state never passes to its successor.
        super(key: ValueKey<String>(cle));

  @override
  ConsumerState<ElementBalayable> createState() => _ElementBalayableState();
}

class _ElementBalayableState extends ConsumerState<ElementBalayable> {
  /// Fraction of the swipe threshold reached, for the background feedback.
  double _progression = 0;
  bool _parti = false;

  /// The side the delete action sits on.
  DismissDirection get _coteSupprimer =>
      ref.read(sensSwipeProvider) == SensSwipe.standard
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd;

  ActionBalayage? _actionVers(DismissDirection direction) =>
      direction == _coteSupprimer ? widget.surSupprimer : widget.surArchiver;

  DismissDirection _directionsPermises(SensSwipe sens) {
    final archiver = widget.surArchiver != null;
    final supprimer = widget.surSupprimer != null;
    if (archiver && supprimer) return DismissDirection.horizontal;
    if (!archiver && !supprimer) return DismissDirection.none;
    final versDebut = (sens == SensSwipe.standard) == supprimer;
    return versDebut ? DismissDirection.endToStart : DismissDirection.startToEnd;
  }

  Future<void> _executer(ActionBalayage action) async {
    if (await action() && mounted) setState(() => _parti = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_parti) return const SizedBox.shrink();
    final sens = ref.watch(sensSwipeProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    _Fond supprimer(AlignmentDirectional cote) => _Fond(
          couleur: scheme.error,
          surCouleur: scheme.onError,
          icone: PhosphorIconsBold.x,
          cote: cote,
          progression: _progression,
        );
    _Fond archiver(AlignmentDirectional cote) => _Fond(
          couleur: scheme.primary,
          surCouleur: scheme.onPrimary,
          icone: PhosphorIconsBold.archive,
          cote: cote,
          progression: _progression,
        );
    const debut = AlignmentDirectional.centerStart;
    const fin = AlignmentDirectional.centerEnd;
    final suppressionAuDebut = sens == SensSwipe.inverse;

    return Semantics(
      customSemanticsActions: {
        if (widget.surArchiver case final action?)
          CustomSemanticsAction(label: widget.libelleArchiver!): () =>
              _executer(action),
        if (widget.surSupprimer case final action?)
          CustomSemanticsAction(label: l10n.actionSupprimer): () =>
              _executer(action),
      },
      child: _clip(Dismissible(
        key: ValueKey(widget.cle),
        direction: _directionsPermises(sens),
        background: suppressionAuDebut ? supprimer(debut) : archiver(debut),
        secondaryBackground:
            suppressionAuDebut ? archiver(fin) : supprimer(fin),
        onUpdate: (details) {
          if (details.reached && !details.previousReached) {
            unawaited(HapticFeedback.selectionClick());
          }
          setState(() => _progression = details.progress);
        },
        confirmDismiss: (direction) async {
          final action = _actionVers(direction);
          return action != null && await action();
        },
        onDismissed: (_) => setState(() => _parti = true),
        child: widget.child,
      )),
    );
  }

  Widget _clip(Widget enfant) => widget.arrondi == null
      ? enfant
      : ClipRRect(borderRadius: widget.arrondi!, child: enfant);
}

/// Coloured strip revealed under a swiped item, deepening up to the threshold.
class _Fond extends StatelessWidget {
  final Color couleur;
  final Color surCouleur;
  final IconData icone;

  /// Edge the icon sits on, the one the item uncovers.
  final AlignmentDirectional cote;
  final double progression;

  /// Default swipe threshold of [Dismissible].
  static const double _seuil = 0.4;
  static const double _opaciteDepart = 0.25;
  static const double _echelleDepart = 0.8;
  static const double _echelleAtteinte = 1.2;
  static const Duration _dureeEchelle = Duration(milliseconds: 120);

  const _Fond({
    required this.couleur,
    required this.surCouleur,
    required this.icone,
    required this.cote,
    required this.progression,
  });

  @override
  Widget build(BuildContext context) {
    final avancee = (progression / _seuil).clamp(0.0, 1.0);
    final atteint = avancee >= 1;
    return Container(
      color: Color.lerp(
          couleur.withValues(alpha: _opaciteDepart), couleur, avancee),
      padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s5),
      alignment: cote,
      child: AnimatedScale(
        scale: atteint
            ? _echelleAtteinte
            : _echelleDepart + (1 - _echelleDepart) * avancee,
        duration: _dureeEchelle,
        child: Icon(icone, color: atteint ? surCouleur : couleur),
      ),
    );
  }
}
