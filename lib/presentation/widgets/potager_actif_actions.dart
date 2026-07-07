import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/repository_providers.dart';
import 'invalidation_vues.dart';

/// Switches the active garden to [potagerId] (ADR-0009 multi-potager) and
/// refreshes every view that depends on it (plan, dashboard, season, climate
/// context, calendar…).
Future<void> definirPotagerActif(WidgetRef ref, String potagerId) async {
  final repo = ref.read(preferencesRepositoryProvider);
  final prefs = await repo.charger();
  await repo.sauvegarder(prefs.copierAvec(potagerActifId: potagerId));
  invaliderVuesDonnees(ref);
}
