/// The `preferences` columns later migrations touch, as of schema v9.
const preferencesV9 =
    'CREATE TABLE "preferences" ('
    '"id" TEXT NOT NULL DEFAULT \'singleton\', '
    '"systeme_unites" TEXT NOT NULL DEFAULT \'metrique\', '
    '"derniere_modification" TEXT NOT NULL, PRIMARY KEY ("id"))';

/// The `parcelles` columns later migrations touch, as of schema v10.
const parcellesV10 =
    'CREATE TABLE "parcelles" ('
    '"id" TEXT NOT NULL, "surface_valeur" REAL NOT NULL, PRIMARY KEY ("id"))';
