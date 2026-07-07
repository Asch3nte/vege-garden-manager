import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../application/providers/database_providers.dart';
import '../application/providers/service_providers.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/database/connection/connexion_native.dart';
import '../infrastructure/services/notification_service_impl.dart';

/// Result of a successful [Bootstrap.initialiser]: the opened [database] the app
/// owns (and must close on shutdown) and a [scopeBuilder] that wraps the app's
/// root widget in a `ProviderScope` configured with the runtime overrides.
///
/// The override list is kept inside [Bootstrap] (inferred) rather than exposed
/// as a field, because Riverpod does not publish its `Override` type under a
/// nameable public symbol.
class ResultatBootstrap {
  /// The opened persistent database, owned by the app.
  final AppDatabase database;

  /// Wraps [child] in the root `ProviderScope` with the runtime overrides.
  final Widget Function(Widget child) scopeBuilder;

  const ResultatBootstrap._(this.database, this.scopeBuilder);
}

/// Wires the platform-specific bootstrap concerns the app needs before its
/// first frame.
///
/// Responsibilities:
///  - open the persistent SQLite database and override [appDatabaseProvider];
///  - initialise the timezone database and set the device's local zone, so
///    scheduled notifications fire at the right wall-clock time (DST included);
///  - initialise the local-notifications plugin.
///
/// Everything here is **local and privacy-preserving**: no network, no account,
/// no remote storage. Tests bypass this entirely by overriding the same
/// providers with in-memory fakes.
class Bootstrap {
  const Bootstrap();

  /// Runs the bootstrap and returns the owned database + a `ProviderScope`
  /// builder carrying the runtime overrides.
  Future<ResultatBootstrap> initialiser() async {
    final database = ouvrirBaseAppli();

    await _initialiserFuseauHoraire();

    final overrides = [
      appDatabaseProvider.overrideWithValue(database),
    ];

    // Initialise the notification plugin via a throwaway container so we use the
    // exact instance the (overridden) provider graph will hand out at runtime.
    final amorce = ProviderContainer(overrides: overrides);
    try {
      final service = amorce.read(notificationServiceProvider);
      if (service is NotificationServiceImpl) {
        await service.initialiser();
      }
    } finally {
      amorce.dispose();
    }

    return ResultatBootstrap._(
      database,
      (child) => ProviderScope(overrides: overrides, child: child),
    );
  }

  /// Loads the timezone database and points `tz.local` at the device's zone.
  ///
  /// Falls back to UTC if the platform can't report its zone (rather than
  /// failing startup): notifications still work, just in UTC, and the failure is
  /// non-fatal.
  Future<void> _initialiserFuseauHoraire() async {
    tzdata.initializeTimeZones();
    try {
      // flutter_timezone >=5 returns a TimezoneInfo; `identifier` is the IANA
      // name (e.g. "Europe/Brussels") the `timezone` package expects.
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Unknown zone: keep the default (UTC). Non-fatal.
    }
  }
}
