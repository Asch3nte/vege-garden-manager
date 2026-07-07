import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pot_a_gerer/infrastructure/services/ouverture_lien_service_impl.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _MockUrlLauncherPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const LaunchOptions(mode: PreferredLaunchMode.platformDefault),
    );
  });

  late _MockUrlLauncherPlatform platform;
  late OuvertureLienServiceImpl service;

  setUp(() {
    platform = _MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = platform;
    service = OuvertureLienServiceImpl();
  });

  test('opens the URL externally when a handler is available', () async {
    when(() => platform.canLaunch(any())).thenAnswer((_) async => true);
    when(() => platform.launchUrl(any(), any()))
        .thenAnswer((_) async => true);

    final resultat = await service.ouvrir(Uri.parse('https://example.org'));

    expect(resultat, isTrue);
    final options =
        verify(() => platform.launchUrl('https://example.org', captureAny()))
            .captured
            .single as LaunchOptions;
    expect(options.mode, PreferredLaunchMode.externalApplication);
  });

  test('returns false without launching when no handler is available',
      () async {
    when(() => platform.canLaunch(any())).thenAnswer((_) async => false);

    final resultat = await service.ouvrir(Uri.parse('https://example.org'));

    expect(resultat, isFalse);
    verifyNever(() => platform.launchUrl(any(), any()));
  });
}
