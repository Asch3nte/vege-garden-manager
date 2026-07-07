import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pot_a_gerer/infrastructure/services/info_application_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InfoApplicationServiceImpl service;

  setUp(() => service = InfoApplicationServiceImpl());

  test('combines version and build number when both are reported', () async {
    PackageInfo.setMockInitialValues(
      appName: "Pot'à Gérer",
      packageName: 'com.example.pot_a_gerer',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    expect(await service.obtenirVersionAffichee(), '1.0.0+1');
  });

  test('falls back to the bare version when no build number is reported',
      () async {
    PackageInfo.setMockInitialValues(
      appName: "Pot'à Gérer",
      packageName: 'com.example.pot_a_gerer',
      version: '1.2.3',
      buildNumber: '',
      buildSignature: '',
    );

    expect(await service.obtenirVersionAffichee(), '1.2.3');
  });
}
