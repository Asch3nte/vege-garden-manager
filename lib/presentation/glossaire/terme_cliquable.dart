import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/couleurs_termes.dart';
import 'page_terme_glossaire.dart';
import 'type_terme_glossaire.dart';

/// A glossary term page **pushed above a modal overlay** (dialog / bottom
/// sheet) on the root navigator: the overlay stays alive underneath, so the
/// system back returns to it exactly as the user left it (associations view,
/// plant sheet…). Term→term navigation from such a page pushes again — back
/// then replays the pages in their opening order, matching the app-wide
/// history contract (docs/15 §8 D#6).
class _RoutePageTerme extends MaterialPageRoute<void> {
  _RoutePageTerme(String idTerme)
      : super(builder: (_) => PageTermeGlossaire(idTerme: idTerme));
}

/// Navigates to the glossary page of [idTerme] from **anywhere** in the app
/// (ADR-0017 D5).
///
/// From a modal overlay (the associations dialog, the plant sheet…) the page
/// is **pushed above it** ([_RoutePageTerme]): back returns to the overlay,
/// which keeps its state. Everywhere else the page is a regular router
/// destination, joining the global shared history.
void ouvrirTermeGlossaire(BuildContext context, String idTerme) {
  final route = ModalRoute.of(context);
  final surOverlay = route is PopupRoute ||
      route is ModalBottomSheetRoute ||
      route is _RoutePageTerme;
  if (surOverlay) {
    Navigator.of(context, rootNavigator: true).push(_RoutePageTerme(idTerme));
  } else {
    context.go(RoutesApp.aideTerme(idTerme));
  }
}

/// An **inline clickable term**: coloured by its glossary kind (the D5 chart),
/// discreetly underlined, tapping opens its glossary page. This is the same
/// visual grammar as the wiki links rendered by `TexteAvecLiens` — one look,
/// everywhere (plant sheets, panels, glossary pages…).
class TermeCliquable extends StatelessWidget {
  /// Prefixed glossary id of the target term (e.g. `famille.solanaceae`).
  final String idTerme;

  /// Text to display.
  final String texte;

  /// Kind of the target term — drives the colour.
  final TypeTermeGlossaire type;

  /// Base style (colour/underline are applied on top of it).
  final TextStyle? style;

  const TermeCliquable({
    super.key,
    required this.idTerme,
    required this.texte,
    required this.type,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = couleursTermesDe(context).couleurDe(type);
    return InkWell(
      onTap: () => ouvrirTermeGlossaire(context, idTerme),
      child: Text(
        texte,
        style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
          color: couleur,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: couleur,
        ),
      ),
    );
  }
}

/// A small « ? » help affordance opening a glossary page (ADR-0017 D5) —
/// used as the `suffixIcon` of form fields whose concept deserves a full
/// explanation (climate, hardiness, soil texture…). Kept deliberately
/// discreet: outlined icon, muted colour, compact hit target.
class AideGlossaire extends StatelessWidget {
  /// Prefixed glossary id of the page to open (e.g. `notion.type-climat`).
  final String idTerme;

  /// Tooltip announcing the destination (defaults to the glossary title).
  final String? infobulle;

  const AideGlossaire({super.key, required this.idTerme, this.infobulle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      tooltip: infobulle,
      onPressed: () => ouvrirTermeGlossaire(context, idTerme),
    );
  }
}

/// A **clickable term chip** (shared by the glossary pages and the app
/// surfaces, e.g. the plant sheet's disease/pest chips): label tinted by the
/// D5 chart, optional tooltip, tapping opens the term page.
class PuceTermeGlossaire extends StatelessWidget {
  /// Prefixed glossary id of the target term.
  final String idTerme;

  /// Chip label.
  final String texte;

  /// Kind of the target term — drives the colour.
  final TypeTermeGlossaire type;

  /// Optional tooltip (e.g. the bioaggressor description).
  final String? infobulle;

  const PuceTermeGlossaire({
    super.key,
    required this.idTerme,
    required this.texte,
    required this.type,
    this.infobulle,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = couleursTermesDe(context).couleurDe(type);
    final puce = ActionChip(
      label: Text(texte),
      labelStyle: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: couleur, fontWeight: FontWeight.w600),
      side: BorderSide(color: couleur.withValues(alpha: 0.5)),
      onPressed: () => ouvrirTermeGlossaire(context, idTerme),
    );
    return infobulle == null ? puce : Tooltip(message: infobulle!, child: puce);
  }
}
