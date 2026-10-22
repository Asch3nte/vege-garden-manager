import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The network canvas node of fiche [id], located by its semantics identifier.
SemanticsFinder noeudReseau(String id) => find.semantics.byPredicate(
  (n) => n.identifier == 'reseau-noeud-$id',
);

/// Logical screen centre of the network canvas node of fiche [id].
Offset centreNoeudReseau(WidgetTester tester, String id) {
  final noeud = noeudReseau(id).evaluate().single;
  var rect = noeud.rect;
  for (SemanticsNode? n = noeud; n != null; n = n.parent) {
    if (n.transform != null) rect = MatrixUtils.transformRect(n.transform!, rect);
  }
  return rect.center / tester.view.devicePixelRatio;
}
