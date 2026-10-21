import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the catalogue shows the Réseau view rather than the sheet list.
class VueReseauNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void choisir(bool reseau) => state = reseau;
}

/// The catalogue's selected view, shared with its app bar.
final vueReseauProvider = NotifierProvider<VueReseauNotifier, bool>(
  VueReseauNotifier.new,
);
