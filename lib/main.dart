import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/bootstrap.dart';
import 'app/router.dart';
import 'app/theme/theme_app.dart';
import 'application/state/preferences_notifier.dart';
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

  runApp(resultat.scopeBuilder(PotAGererApp()));
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
/// go_router navigation shell. The router is built once and held for the widget's
/// lifetime (a [GoRouter] must not be rebuilt on every frame).
///
/// **Must be mounted under a `ProviderScope`** — screens are Riverpod consumers.
/// In production [main] supplies it via `Bootstrap.scopeBuilder`; tests wrap it
/// themselves (with overridden repositories).
///
/// The active [ThemeMode] follows the user's theme preference; until the
/// preferences load (or if they fail), it falls back to `ThemeMode.system`.
class PotAGererApp extends ConsumerWidget {
  PotAGererApp({super.key});

  final GoRouter _routeur = creerRouteur();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(preferencesProvider).value?.theme;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeApp.clair(),
      darkTheme: ThemeApp.sombre(),
      themeMode: _modeTheme(themePref),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _routeur,
    );
  }

  /// Maps the stored theme preference to a Flutter [ThemeMode]; `null`
  /// (not yet loaded) falls back to following the system.
  static ThemeMode _modeTheme(prefs_theme.ThemeApp? pref) => switch (pref) {
        prefs_theme.ThemeApp.clair => ThemeMode.light,
        prefs_theme.ThemeApp.sombre => ThemeMode.dark,
        prefs_theme.ThemeApp.auto || null => ThemeMode.system,
      };
}
