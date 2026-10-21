import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Icon of every actions (overflow) menu.
class IconeMenuActions extends StatelessWidget {
  const IconeMenuActions({super.key});

  @override
  Widget build(BuildContext context) =>
      const Icon(PhosphorIconsRegular.dotsThreeVertical);
}

/// Arrow of every drop-down field.
class IconeDeroulante extends StatelessWidget {
  const IconeDeroulante({super.key});

  @override
  Widget build(BuildContext context) =>
      const Icon(PhosphorIconsRegular.caretDown);
}
