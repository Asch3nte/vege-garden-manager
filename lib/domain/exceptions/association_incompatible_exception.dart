import 'potager_exception.dart';

/// Thrown when two plants that should not be grown together are associated.
///
/// See `docs/05-modele-de-domaine.md` §8.
class AssociationIncompatibleException extends PotagerException {
  final String plante1Id;
  final String plante2Id;

  AssociationIncompatibleException(this.plante1Id, this.plante2Id)
      : super(
          'Plants "$plante1Id" and "$plante2Id" are not compatible companions.',
        );
}
