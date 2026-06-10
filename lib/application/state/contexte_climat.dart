import 'package:riverpod/riverpod.dart';

import '../../domain/entities/potager.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/type_climat.dart';
import '../providers/repository_providers.dart';

/// The (hemisphere, climate) context used to resolve a plant's cultivation
/// windows, derived from the active garden.
///
/// The [hemisphere] comes from the garden's latitude; when there is no position
/// the northern hemisphere is assumed and [hemisphereSuppose] is set, so callers
/// can flag the assumption rather than presenting it silently (cf. the
/// onboarding-location decision). The [climat] is the garden's declared type.
class ContexteClimat {
  final Hemisphere _hemisphere;
  final TypeClimat _climat;
  final bool _hemisphereSuppose;

  const ContexteClimat._(this._hemisphere, this._climat, this._hemisphereSuppose);

  /// Derives the context from [potager] (latitude sign → hemisphere).
  factory ContexteClimat.pour(Potager potager) {
    final latitude = potager.localisation.latitude;
    return ContexteClimat._(
      (latitude ?? 0) >= 0 ? Hemisphere.nord : Hemisphere.sud,
      potager.zoneClimatique.type,
      latitude == null,
    );
  }

  Hemisphere get hemisphere => _hemisphere;
  TypeClimat get climat => _climat;

  /// Whether the northern hemisphere was assumed (no position on the garden).
  bool get hemisphereSuppose => _hemisphereSuppose;
}

/// The active garden's climate context, or `null` when there is no garden.
final contexteClimatProvider = FutureProvider<ContexteClimat?>((ref) async {
  final potager =
      await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
  return potager == null ? null : ContexteClimat.pour(potager);
});
