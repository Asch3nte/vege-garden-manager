/// The `preferences` columns later migrations touch, as of schema v9.
const preferencesV9 =
    'CREATE TABLE "preferences" ('
    '"id" TEXT NOT NULL DEFAULT \'singleton\', '
    '"systeme_unites" TEXT NOT NULL DEFAULT \'metrique\', '
    '"derniere_modification" TEXT NOT NULL, PRIMARY KEY ("id"))';
