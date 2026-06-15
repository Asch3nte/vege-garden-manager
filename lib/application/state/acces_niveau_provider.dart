import 'package:riverpod/riverpod.dart';

import '../../domain/enums/niveau_experience.dart';
import '../../domain/services/acces_niveau.dart';
import 'preferences_notifier.dart';

/// The current [AccesNiveau] progressive-disclosure policy (ADR-0009), derived
/// from the user's experience level.
///
/// Defaults to the most **restrictive** level (débutant) while preferences are
/// still loading, so features never flash open before the real level is known.
final accesNiveauProvider = Provider<AccesNiveau>((ref) {
  final niveau = ref.watch(preferencesProvider).value?.niveauExperience ??
      NiveauExperience.debutant;
  return AccesNiveau(niveau);
});
