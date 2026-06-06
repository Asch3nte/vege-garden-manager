import 'package:flutter/material.dart';

import 'app/bootstrap.dart';

/// Application entry point.
///
/// Runs the platform [Bootstrap] (database, timezone, notifications) before the
/// first frame, then mounts the app inside the configured `ProviderScope`.
/// The UI itself (design system, screens, router) is built on top of this in the
/// Presentation layer — for now a placeholder confirms the app boots and its
/// dependency graph is wired.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final resultat = await const Bootstrap().initialiser();

  runApp(resultat.scopeBuilder(const PotAGererApp()));
}

/// Root widget of Pot'à Gérer.
class PotAGererApp extends StatelessWidget {
  const PotAGererApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pot'à Gérer",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C7A34)),
        useMaterial3: true,
      ),
      home: const _EcranAmorce(),
    );
  }
}

/// Temporary landing screen confirming the app booted. Replaced by the real
/// navigation (onboarding → potager) once the Presentation layer lands.
class _EcranAmorce extends StatelessWidget {
  const _EcranAmorce();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text("Pot'à Gérer", style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Application prête — base de données, fuseau horaire et '
                'notifications initialisés.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
