import 'package:riverpod/riverpod.dart';

import '../providers/langue_provider.dart';
import '../providers/repository_providers.dart';

/// Common name, in the user language, of the crop grown by the plantation of
/// the given id; `null` when it cannot be resolved.
final nomPlantePlantationProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, id) async {
  final langue = ref.watch(codeLangueProvider);
  final plantation =
      await ref.watch(plantationRepositoryProvider).obtenirParId(id);
  if (plantation == null) return null;
  final fiches = await ref.watch(fichePlanteRepositoryProvider.future);
  return (await fiches.obtenirParId(plantation.planteId))?.nomLocalise(langue);
});
