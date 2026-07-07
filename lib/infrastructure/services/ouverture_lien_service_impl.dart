import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../domain/repositories/abstract_ouverture_lien_service.dart';

/// `url_launcher`-backed [AbstractOuvertureLienService].
class OuvertureLienServiceImpl implements AbstractOuvertureLienService {
  @override
  Future<bool> ouvrir(Uri url) async {
    if (!await url_launcher.canLaunchUrl(url)) return false;
    return url_launcher.launchUrl(
      url,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  }
}
