import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart' show Size;
import 'package:flutter_test/flutter_test.dart'
    show WidgetTester, addTearDown, find;
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';

/// The only hosts the app may contact.
const hotesAutorises = {'api.open-meteo.com', 'nominatim.openstreetmap.org'};

/// A manually set position in Brussels.
Localisation get bruxelles =>
    Localisation.manuelle(ville: 'Bruxelles', latitude: 50.85, longitude: 4.35);

/// Sizes the test view to 1600x1000 logical pixels until the end of the test.
void fixerVueLarge(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Taps the last widget showing [libelle], then waits with [attendre].
Future<void> taper(
  WidgetTester tester,
  String libelle,
  Future<void> Function(WidgetTester tester) attendre,
) async {
  await tester.tap(find.text(libelle).last);
  await attendre(tester);
}

bool _gardesPrets = false;

void _preparerReponsesFactices() {
  if (_gardesPrets) return;
  _gardesPrets = true;
  registerFallbackValue(Uri());
  registerFallbackValue(const Stream<List<int>>.empty());
}

class _MockHttpClient extends Mock implements HttpClient {}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

class _ReponseVide extends Mock implements HttpClientResponse {
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => const Stream<List<int>>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

/// Sandbox answering 503 to every HTTP request without opening a socket, and
/// recording the requested URIs.
class GardeReseau extends HttpOverrides {
  final List<Uri> _requetes = [];

  /// Makes a new guard the global override until the end of the current test.
  /// Needed where frames run outside the test zone (live binding). Must not be
  /// nested inside [avecGardeReseau].
  static GardeReseau installer() {
    final garde = GardeReseau();
    if (Zone.current[#gardeReseau] != null) {
      throw StateError('installer() must not run inside avecGardeReseau.');
    }
    // Outside a zone override, `current` is the global override.
    final precedent = HttpOverrides.current;
    HttpOverrides.global = garde;
    addTearDown(() => HttpOverrides.global = precedent);
    return garde;
  }

  /// Requested URIs, in order.
  List<Uri> get requetes => List.unmodifiable(_requetes);

  /// Distinct hosts requested.
  Set<String> get hotes => _requetes.map((u) => u.host).toSet();

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = _MockHttpClient();
    _preparerReponsesFactices();
    final requete = _requete();
    when(() => client.openUrl(any(), any())).thenAnswer((i) async {
      _requetes.add(i.positionalArguments[1] as Uri);
      return requete;
    });
    when(() => client.close(force: any(named: 'force'))).thenReturn(null);
    return client;
  }

  HttpClientRequest _requete() {
    final entetes = _MockHttpHeaders();
    when(() => entetes.set(any(), any<Object>())).thenReturn(null);
    final reponse = _ReponseVide();
    final reponseEntetes = _MockHttpHeaders();
    when(() => reponseEntetes.forEach(any())).thenReturn(null);
    when(() => reponse.statusCode).thenReturn(503);
    when(() => reponse.contentLength).thenReturn(-1);
    when(() => reponse.isRedirect).thenReturn(false);
    when(() => reponse.persistentConnection).thenReturn(false);
    when(() => reponse.reasonPhrase).thenReturn('Service Unavailable');
    when(() => reponse.redirects).thenReturn(const []);
    when(() => reponse.headers).thenReturn(reponseEntetes);
    final requete = _MockHttpClientRequest();
    when(() => requete.headers).thenReturn(entetes);
    when(() => requete.addStream(any())).thenAnswer((i) async {
      await (i.positionalArguments.first as Stream<List<int>>).drain<void>();
    });
    when(() => requete.close()).thenAnswer((_) async => reponse);
    return requete;
  }
}

/// Runs [corps] with a [GardeReseau] taking precedence over any global override.
T avecGardeReseau<T>(T Function(GardeReseau garde) corps) {
  final garde = GardeReseau();
  return Zone.current
      .fork(zoneValues: {#gardeReseau: true})
      .run(
        () => HttpOverrides.runZoned(
          () => corps(garde),
          createHttpClient: garde.createHttpClient,
        ),
      );
}
