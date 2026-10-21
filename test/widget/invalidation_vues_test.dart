import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/favoris_notifier.dart';
import 'package:pot_a_gerer/presentation/widgets/invalidation_vues.dart';

import '../helpers/favoris_mock.dart';

void main() {
  testWidgets('favourites reload after a global data change', (tester) async {
    final favoris = favorisEnMemoire({'tomate'});
    late WidgetRef capture;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [favoriRepositoryProvider.overrideWithValue(favoris)],
        child: Consumer(
          builder: (context, ref, _) {
            capture = ref;
            ref.watch(favorisProvider);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(capture.read(favorisProvider).value, {'tomate'});

    // The base is wiped behind the cached state (factory reset, import).
    when(() => favoris.obtenirIds()).thenAnswer((_) async => {});
    invaliderVuesDonnees(capture);
    await tester.pumpAndSettle();

    expect(capture.read(favorisProvider).value, isEmpty);
  });
}
