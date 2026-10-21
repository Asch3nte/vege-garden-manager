/// Simplified climate classification (Köppen-inspired) attached to a potager.
///
/// Combined with [ZoneRusticite] it captures both the general climate and the
/// local cold tolerance (an oceanic climate in Brittany ≠ an oceanic climate in
/// Belgium).
enum TypeClimat {
  tropical,
  subtropical,
  aride,
  semiAride,
  mediterraneen,
  oceanique,
  continental,
  montagnard,
  polaire,
}
