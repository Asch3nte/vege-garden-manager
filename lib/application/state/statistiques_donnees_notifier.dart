import 'package:riverpod/riverpod.dart';

import '../../domain/value_objects/statistiques_stockage.dart';
import '../providers/service_providers.dart';

/// Local-storage statistics for the data-transparency settings panel
/// (docs/11 §6): per-table record counts + the database's on-disk size.
///
/// A one-shot read of [AbstractStatistiquesDonneesService]; the panel can
/// `ref.invalidate` it to refresh after the user changes their data.
final statistiquesDonneesProvider =
    FutureProvider<StatistiquesStockage>((ref) async {
  return ref.watch(statistiquesDonneesServiceProvider).obtenirStatistiques();
});
