import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../application/state/geste_groupe.dart';
import '../../domain/entities/tache.dart';
import '../../l10n/app_localizations.dart';
import 'element_balayable.dart';

/// A task line swiped to tick it off or reopen it (it stays listed) or to
/// delete it.
class TacheBalayable extends StatelessWidget {
  final Tache tache;
  final VoidCallback onBasculer;
  final ActionBalayage onSupprimer;
  final BorderRadius? arrondi;
  final Widget child;

  const TacheBalayable({
    super.key,
    required this.tache,
    required this.onBasculer,
    required this.onSupprimer,
    required this.child,
    this.arrondi,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faite = tache.estFaite;
    return ElementBalayable(
      cle: tache.id,
      arrondi: arrondi,
      surArchiver: () async {
        onBasculer();
        return false;
      },
      libelleArchiver: faite ? l10n.tacheRouvrir : l10n.tacheMarquerFaite,
      iconeArchiver: faite
          ? PhosphorIconsBold.arrowCounterClockwise
          : PhosphorIconsBold.archive,
      surSupprimer: onSupprimer,
      child: child,
    );
  }
}

/// A gesture group summary swiped to tick all its tasks off, or reopen them
/// once all are done; deleting stays per task.
class GesteBalayable extends StatelessWidget {
  final GesteGroupe geste;
  final VoidCallback onBasculer;
  final Widget child;

  const GesteBalayable({
    super.key,
    required this.geste,
    required this.onBasculer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faites = geste.toutesFaites;
    return ElementBalayable(
      cle: 'groupe-${geste.type.name}',
      surArchiver: () async {
        onBasculer();
        return false;
      },
      libelleArchiver:
          faites ? l10n.gesteGroupeToutRouvrir : l10n.gesteGroupeToutCocher,
      iconeArchiver: faites
          ? PhosphorIconsBold.arrowCounterClockwise
          : PhosphorIconsBold.archive,
      child: child,
    );
  }
}
