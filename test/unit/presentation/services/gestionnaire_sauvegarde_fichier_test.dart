import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/exceptions/sauvegarde_invalide_exception.dart';
import 'package:pot_a_gerer/presentation/services/gestionnaire_sauvegarde_fichier.dart';

void main() {
  late Directory cache;
  late List<String> partages;
  late GestionnaireSauvegardeFichier gestionnaire;
  Future<List<int>?> Function() lecture = () async => null;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('cache_test');
    partages = [];
    gestionnaire = GestionnaireSauvegardeFichier(
      dossierCache: () async => cache,
      partagerFichier: (chemin, sujet) async => partages.add(chemin),
      lireFichierChoisi: () => lecture(),
    );
  });
  tearDown(() => cache.delete(recursive: true));

  group('partager', () {
    test('writes the backup in a dedicated cache folder and shares it',
        () async {
      await gestionnaire.partager('{"a":1}', 'export.json');

      final chemin = partages.single;
      expect(File(chemin).parent.parent.path, cache.path);
      expect(await File(chemin).readAsString(), '{"a":1}');
    });

    test('removes the previous exports before writing a new one', () async {
      await gestionnaire.partager('{"a":1}', 'ancien.json');
      await gestionnaire.partager('{"a":2}', 'nouveau.json');

      final dossier = File(partages.last).parent;
      final restants = dossier.listSync().map((f) => f.uri.pathSegments.last);
      expect(restants, ['nouveau.json']);
    });
  });

  group('choisirEtLire', () {
    test('returns null when the picker is cancelled', () async {
      lecture = () async => null;

      expect(await gestionnaire.choisirEtLire(), isNull);
    });

    test('decodes UTF-8 content', () async {
      lecture = () async => utf8.encode('{"nom":"Été"}');

      expect(await gestionnaire.choisirEtLire(), '{"nom":"Été"}');
    });

    test('rejects content that is not UTF-8 with a typed exception', () {
      lecture = () async => [0xff, 0xfe, 0x00];

      expect(gestionnaire.choisirEtLire(),
          throwsA(isA<SauvegardeInvalideException>()));
    });

    test('rejects an unreadable file with a typed exception', () {
      lecture = () async => throw const FileSystemException('denied');

      expect(gestionnaire.choisirEtLire(),
          throwsA(isA<SauvegardeInvalideException>()));
    });
  });
}
