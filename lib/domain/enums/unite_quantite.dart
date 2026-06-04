/// Physical nature of a unit. Conversions are only possible between units that
/// share the same nature (mass↔mass, volume↔volume). Counting units (`piece`,
/// `botte`) each form their own nature and are never cross-convertible.
enum NatureUnite { masse, volume, piece, botte }

/// Units in which a quantity (e.g. a harvest) can be expressed.
///
/// See `docs/05-modele-de-domaine.md` §5.
enum UniteQuantite { g, kg, piece, botte, litre, ml }

/// Conversion metadata for [UniteQuantite].
extension UniteQuantiteX on UniteQuantite {
  /// The nature this unit belongs to.
  NatureUnite get nature => switch (this) {
        UniteQuantite.g || UniteQuantite.kg => NatureUnite.masse,
        UniteQuantite.ml || UniteQuantite.litre => NatureUnite.volume,
        UniteQuantite.piece => NatureUnite.piece,
        UniteQuantite.botte => NatureUnite.botte,
      };

  /// Factor used to convert a value expressed in this unit into the base unit of
  /// its nature (grams for mass, millilitres for volume, 1 for counting units).
  double get facteurVersBase => switch (this) {
        UniteQuantite.g => 1,
        UniteQuantite.kg => 1000,
        UniteQuantite.ml => 1,
        UniteQuantite.litre => 1000,
        UniteQuantite.piece => 1,
        UniteQuantite.botte => 1,
      };
}
