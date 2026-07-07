import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/repositories/abstract_info_application_service.dart';

/// `package_info_plus`-backed [AbstractInfoApplicationService].
class InfoApplicationServiceImpl implements AbstractInfoApplicationService {
  @override
  Future<String> obtenirVersionAffichee() async {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
  }
}
