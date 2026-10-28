import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart' show addTearDown;
import 'package:mocktail/mocktail.dart';

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
  /// Needed where frames run outside the test zone (live binding).
  static GardeReseau installer() {
    final garde = GardeReseau();
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
    registerFallbackValue(Uri());
    registerFallbackValue(const Stream<List<int>>.empty());
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
  return HttpOverrides.runZoned(
    () => corps(garde),
    createHttpClient: garde.createHttpClient,
  );
}
