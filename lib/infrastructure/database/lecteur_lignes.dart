import 'dart:developer' as developer;

import '../../domain/exceptions/invariant_domaine_exception.dart';

/// Reports an unreadable row of [table] identified by [id].
typedef SignalerLigneIllisible = void Function(
    String table, String id, Object erreur);

/// Maps database rows to entities, setting aside each row that no longer forms
/// a valid entity instead of failing the whole read. The row stays untouched
/// in the database.
class LecteurLignes {
  final SignalerLigneIllisible? _signaler;

  const LecteurLignes([this._signaler]);

  /// Entities of the readable [lignes] of [table].
  List<E> lire<R, E>(String table, Iterable<R> lignes,
      E Function(R) versEntite, String Function(R) idDe) {
    final entites = <E>[];
    for (final ligne in lignes) {
      final entite = lireUne(table, ligne, versEntite, idDe);
      if (entite != null) entites.add(entite);
    }
    return List.unmodifiable(entites);
  }

  /// Entity of [ligne], or `null` when it is absent or unreadable.
  E? lireUne<R, E>(String table, R? ligne, E Function(R) versEntite,
      String Function(R) idDe) {
    if (ligne == null) return null;
    try {
      return versEntite(ligne);
    } on InvariantDomaineException catch (e) {
      _ecarter(table, idDe(ligne), e);
    } on FormatException catch (e) {
      _ecarter(table, idDe(ligne), e);
    } on ArgumentError catch (e) {
      // An unknown stored enum value.
      _ecarter(table, idDe(ligne), e);
    } on TypeError catch (e) {
      // A stored JSON or YAML value of an unexpected shape.
      _ecarter(table, idDe(ligne), e);
    }
    return null;
  }

  void _ecarter(String table, String id, Object erreur) {
    developer.log('Unreadable row $table/$id set aside',
        name: 'database', error: erreur);
    _signaler?.call(table, id, erreur);
  }
}
