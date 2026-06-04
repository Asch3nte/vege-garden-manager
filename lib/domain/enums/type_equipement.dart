/// Type of equipment that can be installed on a parcelle (or shared at the
/// potager level).
///
/// A functional review of this list is planned (see roadmap V1.1). Each type
/// maps to a provisional [EffetEquipement] via `EffetEquipement.pourType`.
/// See `docs/05-modele-de-domaine.md` §5.
enum TypeEquipement {
  oya,
  gouttesAGoutte,
  tuteur,
  treillis,
  tunnel,
  serreSemis,
  chassis,
  cloche,
  voileHivernage,
  filetAntiInsecte,
  hotelInsectes,
  composteur,
  recuperateurEau,
  autre,
}
