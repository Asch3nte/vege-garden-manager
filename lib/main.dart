import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap.dart';
import 'app/router.dart';
import 'app/theme/theme_app.dart';
import 'application/state/preferences_notifier.dart';
import 'domain/enums/langue.dart';
import 'domain/enums/theme_app.dart' as prefs_theme;
import 'l10n/app_localizations.dart';

/// Application entry point.
///
/// Runs the platform [Bootstrap] (database, timezone, notifications) before the
/// first frame, then mounts the app inside the configured `ProviderScope`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _enregistrerLicencesPolices();

  final resultat = await const Bootstrap().initialiser();

  runApp(resultat.scopeBuilder(const PotAGererApp()));
}

/// Registers the SIL OFL 1.1 licences of the embedded Manrope & Inter fonts in
/// Flutter's [LicenseRegistry], so they surface in the standard "Licenses" page.
///
/// Loading is lazy (the registry pulls the stream only when the licence page is
/// opened); a missing file degrades gracefully to an empty entry rather than
/// crashing startup.
void _enregistrerLicencesPolices() {
  LicenseRegistry.addLicense(() async* {
    for (final chemin in const [
      'assets/fonts/OFL-Manrope.txt',
      'assets/fonts/OFL-Inter.txt',
    ]) {
      try {
        final texte = await rootBundle.loadString(chemin);
        yield LicenseEntryWithLineBreaks(const ['Manrope', 'Inter'], texte);
      } catch (erreur) {
        debugPrint('Licence police introuvable ($chemin) : $erreur');
      }
    }
  });
}

/// Root widget of Pot'à Gérer.
///
/// Wires the « Carnet vivant » themes, the French localization delegates and the
/// go_router navigation shell. The router comes from `routeurProvider`, which
/// caches a single instance for the app's lifetime (it must not be rebuilt on
/// every frame).
///
/// **Must be mounted under a `ProviderScope`** — screens are Riverpod consumers.
/// In production [main] supplies it via `Bootstrap.scopeBuilder`; tests wrap it
/// themselves (with overridden repositories).
///
/// The active [ThemeMode] follows the user's theme preference; until the
/// preferences load (or if they fail), it falls back to `ThemeMode.system`.
class PotAGererApp extends ConsumerWidget {
  const PotAGererApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider).value;
    // Cached for the app's lifetime by the provider (a GoRouter must not be
    // rebuilt every frame).
    final routeur = ref.watch(routeurProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeApp.clair(),
      darkTheme: ThemeApp.sombre(),
      themeMode: _modeTheme(prefs?.theme),
      locale: _localeEffective(prefs?.langue),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: routeur,
    );
  }

  /// Maps the stored theme preference to a Flutter [ThemeMode]; `null`
  /// (not yet loaded) falls back to following the system.
  static ThemeMode _modeTheme(prefs_theme.ThemeApp? pref) => switch (pref) {
        prefs_theme.ThemeApp.clair => ThemeMode.light,
        prefs_theme.ThemeApp.sombre => ThemeMode.dark,
        prefs_theme.ThemeApp.auto || null => ThemeMode.system,
      };

  /// Maps the stored language preference to a Flutter [Locale]; `auto` (or not
  /// yet loaded) returns `null`, letting `MaterialApp` fall back to its default
  /// system-locale resolution against `supportedLocales`.
  static Locale? _localeEffective(Langue? pref) => switch (pref) {
        Langue.fr => const Locale('fr'),
        Langue.en => const Locale('en'),
        Langue.auto || null => null,
      };
}
