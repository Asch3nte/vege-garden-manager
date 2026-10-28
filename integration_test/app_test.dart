import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'scenario_demarrage.dart';
import 'scenario_parcours_donnees.dart';
import 'scenario_reseau.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('demarrage', scenarioDemarrage);
  group('parcours donnees', scenarioParcoursDonnees);
  group('reseau', scenarioReseau);
}
