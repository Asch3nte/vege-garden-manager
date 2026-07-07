import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/repository_providers.dart';
import '../../domain/entities/bioagresseur.dart';
import '../../domain/entities/famille_botanique.dart';

/// The reference data the glossary derives from (ADR-0017, D1): all botanical
/// families and all bioaggressors, loaded once from the embedded YAML.
typedef DonneesGlossaire = ({
  List<FamilleBotanique> familles,
  List<Bioagresseur> bioagresseurs,
});

/// Gathers the YAML references the glossary needs. The glossary itself is
/// built on the Presentation side (`construireGlossaire`) because its texts
/// depend on `AppLocalizations`, which only widgets can resolve.
final glossaireDonneesProvider = FutureProvider<DonneesGlossaire>((ref) async {
  final familles =
      await (await ref.watch(familleBotaniqueRepositoryProvider.future))
          .obtenirToutes();
  final bioagresseurs =
      await (await ref.watch(bioagresseurRepositoryProvider.future))
          .obtenirTous();
  return (familles: familles, bioagresseurs: bioagresseurs);
});
