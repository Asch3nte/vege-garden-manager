/// What a harvest was used for. `compost` records losses without skewing the
/// edible totals. See `docs/05-modele-de-domaine.md` §5.
enum DestinationRecolte {
  consommationFraiche,
  conservation,
  don,
  semences,
  compost,
  autre,
}
