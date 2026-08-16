/* catalogue-data.jsx — bibliothèque de plantes du Carnet vivant.
   Chaque fiche : variétés, sol, exposition, eau, difficulté, gabarit,
   fenêtres semis/récolte (mois 0-11) et associations (bons compagnons /
   à éviter). Sert la vue Fiches ET la vue Réseau.
   Exports : CATS, CAT_ORDER, PLANTS, plantById, plantMatches, goodEdges */

const CATS = {
  fl:  { label: "Fruits-légumes",  color: "var(--c-warm)" },
  aro: { label: "Aromates",        color: "var(--c-green-mid)" },
  rac: { label: "Racines",         color: "var(--c-terre)" },
  gri: { label: "Légumineuses",    color: "var(--c-green-deep)" },
  feu: { label: "Salades",         color: "var(--c-primary)" },
  pf:  { label: "Petits fruits",   color: "var(--c-bordeaux)" },
};
const CAT_ORDER = ["fl", "aro", "rac", "gri", "feu", "pf"];
const DIFF = ["", "Facile", "Moyen", "Exigeant"];

const PLANTS = [
  { id: "tomate", name: "Tomate", icon: "ph-fill ph-orange-slice", cat: "fl",
    varietes: ["Cœur de bœuf", "Marmande", "Cerise", "Noire de Crimée"],
    sol: "Riche & drainé", expo: "Plein soleil", eau: "Régulier", diff: 2, haut: "1–2 m", espace: "50 cm",
    semis: [2, 3], recolte: [6, 9], good: ["basilic", "persil", "carotte", "poireau", "laitue"], bad: ["concombre"],
    desc: "Star du potager d'été, gourmande en soleil et en eau." },
  { id: "aubergine", name: "Aubergine", icon: "ph-fill ph-plant", cat: "fl",
    varietes: ["Violette longue", "Barbentane", "Ronde de Valence"],
    sol: "Riche & chaud", expo: "Plein soleil", eau: "Régulier", diff: 3, haut: "70–90 cm", espace: "60 cm",
    semis: [1, 2], recolte: [6, 9], good: ["basilic", "haricot", "poivron"], bad: [],
    desc: "Chaleureuse et exigeante, parfaite sous serre." },
  { id: "poivron", name: "Poivron", icon: "ph-fill ph-pepper", cat: "fl",
    varietes: ["Doux long", "California", "Espelette"],
    sol: "Riche & drainé", expo: "Plein soleil", eau: "Régulier", diff: 2, haut: "60–80 cm", espace: "50 cm",
    semis: [1, 3], recolte: [6, 9], good: ["basilic", "tomate", "carotte"], bad: [],
    desc: "Aime la chaleur ; doux ou piquant selon la variété." },
  { id: "courgette", name: "Courgette", icon: "ph-fill ph-leaf", cat: "fl",
    varietes: ["Ronde de Nice", "Verte des maraîchers", "Jaune"],
    sol: "Frais & riche", expo: "Soleil", eau: "Abondant", diff: 1, haut: "Étalée 1 m", espace: "1 m",
    semis: [3, 4], recolte: [5, 8], good: ["haricot", "concombre", "pois"], bad: [],
    desc: "Très productive ; une plante nourrit la famille." },
  { id: "concombre", name: "Concombre", icon: "ph-fill ph-plant", cat: "fl",
    varietes: ["Marketmore", "Le généreux", "Blanc"],
    sol: "Riche & frais", expo: "Soleil", eau: "Abondant", diff: 2, haut: "Grimpant 1,5 m", espace: "60 cm",
    semis: [3, 4], recolte: [5, 8], good: ["haricot", "laitue", "pois"], bad: ["tomate"],
    desc: "Rafraîchissant ; grimpe volontiers sur un treillis." },
  { id: "basilic", name: "Basilic", icon: "ph-fill ph-leaf", cat: "aro",
    varietes: ["Grand vert", "Pourpre", "Fin citron"],
    sol: "Léger & frais", expo: "Soleil", eau: "Régulier", diff: 1, haut: "30–50 cm", espace: "25 cm",
    semis: [2, 4], recolte: [5, 9], good: ["tomate", "poivron", "aubergine"], bad: [],
    desc: "Compagnon idéal de la tomate ; éloigne les pucerons." },
  { id: "thym", name: "Thym", icon: "ph-fill ph-leaf", cat: "aro",
    varietes: ["Commun", "Citron", "Serpolet"],
    sol: "Sec & caillouteux", expo: "Plein soleil", eau: "Faible", diff: 1, haut: "20–30 cm", espace: "30 cm",
    semis: [2, 4], recolte: [4, 9], good: ["laitue", "fraise"], bad: [],
    desc: "Vivace méditerranéenne, increvable et mellifère." },
  { id: "persil", name: "Persil", icon: "ph-fill ph-leaf", cat: "aro",
    varietes: ["Plat", "Frisé"],
    sol: "Frais & humifère", expo: "Mi-ombre", eau: "Régulier", diff: 1, haut: "25 cm", espace: "20 cm",
    semis: [2, 7], recolte: [4, 11], good: ["tomate", "carotte", "radis"], bad: [],
    desc: "Bisannuel ; lève lentement, à semer tôt." },
  { id: "menthe", name: "Menthe", icon: "ph-fill ph-leaf", cat: "aro",
    varietes: ["Verte", "Poivrée", "Marocaine"],
    sol: "Frais", expo: "Mi-ombre", eau: "Abondant", diff: 1, haut: "40–60 cm", espace: "À contenir",
    semis: [3, 5], recolte: [5, 10], good: ["tomate"], bad: ["persil"],
    desc: "Envahissante : à cultiver en pot pour la maîtriser." },
  { id: "carotte", name: "Carotte", icon: "ph-fill ph-carrot", cat: "rac",
    varietes: ["Nantaise", "De Colmar", "Touchon"],
    sol: "Profond & meuble", expo: "Soleil", eau: "Modéré", diff: 2, haut: "Racine 20 cm", espace: "5 cm",
    semis: [2, 6], recolte: [5, 10], good: ["poireau", "radis", "laitue", "pois", "tomate"], bad: ["betterave"],
    desc: "Le poireau éloigne sa mouche : duo gagnant." },
  { id: "radis", name: "Radis", icon: "ph-fill ph-carrot", cat: "rac",
    varietes: ["De 18 jours", "Rond rouge", "Glaçon"],
    sol: "Léger & frais", expo: "Soleil", eau: "Régulier", diff: 1, haut: "Racine 5 cm", espace: "3 cm",
    semis: [2, 8], recolte: [3, 9], good: ["laitue", "carotte", "haricot", "pois"], bad: [],
    desc: "Express : récolte en 3–4 semaines, idéal débutant." },
  { id: "betterave", name: "Betterave", icon: "ph-fill ph-carrot", cat: "rac",
    varietes: ["Détroit", "Crapaudine", "Chioggia"],
    sol: "Profond & frais", expo: "Soleil", eau: "Modéré", diff: 1, haut: "Racine 10 cm", espace: "10 cm",
    semis: [3, 5], recolte: [6, 10], good: ["laitue"], bad: ["carotte"],
    desc: "Rustique ; feuilles et racines se mangent." },
  { id: "poireau", name: "Poireau", icon: "ph-fill ph-plant", cat: "rac",
    varietes: ["Bleu de Solaise", "Monstrueux", "Gros long"],
    sol: "Profond & riche", expo: "Soleil", eau: "Régulier", diff: 2, haut: "Fût 25 cm", espace: "10 cm",
    semis: [1, 3], recolte: [8, 11], good: ["carotte", "tomate", "laitue"], bad: ["haricot", "pois"],
    desc: "Rustique l'hiver ; protège la carotte de sa mouche." },
  { id: "haricot", name: "Haricot", icon: "ph-fill ph-plant", cat: "gri",
    varietes: ["Beurre nain", "Coco", "Mangetout grimpant"],
    sol: "Léger & frais", expo: "Soleil", eau: "Régulier", diff: 1, haut: "Nain 40 cm / Rame 2 m", espace: "10 cm",
    semis: [4, 6], recolte: [6, 9], good: ["courgette", "concombre", "laitue", "radis", "fraise"], bad: ["poireau"],
    desc: "Fixe l'azote ; enrichit le sol pour ses voisins." },
  { id: "pois", name: "Pois", icon: "ph-fill ph-plant", cat: "gri",
    varietes: ["Petit provençal", "Mangetout", "Téléphone"],
    sol: "Frais & meuble", expo: "Soleil", eau: "Régulier", diff: 1, haut: "Rame 1–1,5 m", espace: "5 cm",
    semis: [1, 3], recolte: [4, 6], good: ["carotte", "radis", "concombre", "laitue"], bad: ["poireau"],
    desc: "Se sème tôt ; comme le haricot, enrichit le sol." },
  { id: "laitue", name: "Laitue", icon: "ph-fill ph-leaf", cat: "feu",
    varietes: ["Batavia", "Feuille de chêne", "Romaine"],
    sol: "Frais & humifère", expo: "Mi-ombre", eau: "Régulier", diff: 1, haut: "20–25 cm", espace: "25 cm",
    semis: [1, 8], recolte: [3, 10], good: ["carotte", "radis", "fraise", "concombre", "haricot"], bad: [],
    desc: "Pousse vite ; intercale entre les cultures lentes." },
  { id: "mache", name: "Mâche", icon: "ph-fill ph-leaf", cat: "feu",
    varietes: ["Verte de Cambrai", "Coquille", "À grosse graine"],
    sol: "Tassé & frais", expo: "Mi-ombre", eau: "Modéré", diff: 1, haut: "10 cm", espace: "10 cm",
    semis: [7, 8], recolte: [9, 11], good: ["fraise", "poireau"], bad: [],
    desc: "Salade d'hiver ; se sème en fin d'été." },
  { id: "fraise", name: "Fraise", icon: "ph-fill ph-cherries", cat: "pf",
    varietes: ["Gariguette", "Mara des bois", "Charlotte"],
    sol: "Riche & drainé", expo: "Soleil", eau: "Régulier", diff: 1, haut: "20 cm", espace: "30 cm",
    semis: [8, 8], recolte: [4, 6], good: ["laitue", "haricot", "mache", "thym"], bad: [],
    desc: "Vivace gourmande ; se plante en fin d'été." },
];

const _byId = {};
PLANTS.forEach((p) => { _byId[p.id] = p; });
const plantById = (id) => _byId[id];

function plantMatches(p, q) {
  if (!q) return true;
  const s = q.trim().toLowerCase();
  if (!s) return true;
  const hay = [
    p.name, p.sol, p.expo, p.eau, DIFF[p.diff], CATS[p.cat].label,
    ...p.varietes,
    ...p.good.map((id) => _byId[id] && _byId[id].name),
  ].filter(Boolean).join(" ").toLowerCase();
  return hay.includes(s);
}

// paires d'associations uniques (good / bad), pour la vue Réseau
function goodEdges() {
  const seen = new Set();
  const edges = [];
  const add = (a, b, type) => {
    if (!_byId[b]) return;
    const k = [a, b].sort().join("|");
    if (seen.has(k)) return;
    seen.add(k);
    edges.push({ a, b, type });
  };
  PLANTS.forEach((p) => p.good.forEach((q) => add(p.id, q, "good")));
  PLANTS.forEach((p) => p.bad.forEach((q) => add(p.id, q, "bad")));
  return edges;
}

Object.assign(window, { CATS, CAT_ORDER, DIFF, PLANTS, plantById, plantMatches, goodEdges });
