/* potager.jsx — « Mon potager » : plan vu de dessus tapable + détail de zone.
   3 traitements du plan (grille / spatial / plan+liste) + 1 écran détail.
   Pour chaque culture : stade de croissance, variété, prochaine tâche.
   Exports : PotagerGrille, PotagerMap, PotagerListe, ZoneDetail */

const STAGES = ["Semis", "Jeune pousse", "Croissance", "Floraison", "Récolte"];

const ZONES = [
  { id: "nord", name: "Carré nord", dims: "1,2 × 1,2 m", sun: "Plein soleil", water: "1×/jour",
    color: "var(--c-warm)", icon: "ph-fill ph-orange-slice",
    crops: [
      { name: "Tomate", variete: "Cœur de bœuf", stage: 4, color: "var(--c-warm)", icon: "ph-fill ph-orange-slice", task: "Arroser", due: "Aujourd'hui", ok: false },
      { name: "Basilic", variete: "Grand vert", stage: 3, color: "var(--c-green-mid)", icon: "ph-fill ph-leaf", task: "Pincer les fleurs", due: "Dans 2 j", ok: true },
    ] },
  { id: "serre", name: "Serre", dims: "2 × 3 m", sun: "Abrité", water: "Goutte-à-goutte",
    color: "var(--c-aubergine)", icon: "ph-fill ph-plant",
    crops: [
      { name: "Aubergine", variete: "Violette longue", stage: 5, color: "var(--c-aubergine)", icon: "ph-fill ph-plant", task: "Récolter", due: "À maturité", ok: false },
      { name: "Piment", variete: "Doux long", stage: 4, color: "var(--c-bordeaux)", icon: "ph-fill ph-pepper", task: "Arroser", due: "Aujourd'hui", ok: false },
    ] },
  { id: "sud", name: "Carré sud", dims: "1,2 × 1,2 m", sun: "Soleil", water: "1×/2 jours",
    color: "var(--c-green-deep)", icon: "ph-fill ph-leaf",
    crops: [
      { name: "Courgette", variete: "Ronde de Nice", stage: 4, color: "var(--c-green-deep)", icon: "ph-fill ph-leaf", task: "Surveiller oïdium", due: "Dans 3 j", ok: true },
      { name: "Haricot", variete: "Beurre nain", stage: 3, color: "var(--c-primary)", icon: "ph-fill ph-plant", task: "Tuteurer", due: "Demain", ok: true },
    ] },
  { id: "aromates", name: "Bac aromates", dims: "0,8 × 0,4 m", sun: "Mi-ombre", water: "2×/semaine",
    color: "var(--c-green-mid)", icon: "ph-fill ph-leaf",
    crops: [
      { name: "Romarin", variete: "Officinal", stage: 5, color: "var(--c-green-deep)", icon: "ph-fill ph-needle", task: "—", due: "Établi", ok: true },
      { name: "Thym", variete: "Citron", stage: 5, color: "var(--c-green-mid)", icon: "ph-fill ph-leaf", task: "Tailler", due: "Dans 5 j", ok: true },
      { name: "Origan", variete: "Commun", stage: 4, color: "var(--c-primary)", icon: "ph-fill ph-leaf", task: "—", due: "Établi", ok: true },
    ] },
  { id: "bordure", name: "Bordure sud", dims: "3 × 0,4 m", sun: "Soleil", water: "1×/jour",
    color: "var(--c-bordeaux)", icon: "ph-fill ph-cherries",
    crops: [
      { name: "Fraise", variete: "Gariguette", stage: 5, color: "var(--c-bordeaux)", icon: "ph-fill ph-cherries", task: "Récolter", due: "À maturité", ok: false },
    ] },
];

const dueToday = (z) => z.crops.some((c) => /aujourd/i.test(c.due) || /maturit/i.test(c.due));
const byId = (id) => ZONES.find((z) => z.id === id);

// — chrome partagé —
function PDots() {
  return <span className="dots"><i className="ph-fill ph-cell-signal-full"></i><i className="ph-fill ph-wifi-high"></i><i className="ph-fill ph-battery-high"></i></span>;
}
function PNav({ active = "Potager" }) {
  const items = [["house", "Accueil"], ["plant", "Potager"], ["book-open", "Catalogue"], ["calendar-blank", "Calendrier"], ["dots-three", "Plus"]];
  return (
    <div className="bnav">
      {items.map(([i, l]) => {
        const on = l === active;
        return <div className={"nav" + (on ? " active" : "")} key={l}><i className={"ph" + (on ? "-fill" : "") + " ph-" + i}></i><span>{l}</span></div>;
      })}
    </div>
  );
}

function Stage({ n, showLabel = true }) {
  return (
    <span className="stage">
      {[1, 2, 3, 4, 5].map((i) => <span key={i} className={"seg" + (i <= n ? " on" : "")}></span>)}
      {showLabel && <span className="slab">{STAGES[n - 1]}</span>}
    </span>
  );
}

// planche réutilisable (overview)
function Bed({ z, style, span }) {
  return (
    <div className={"bed" + (span ? " span" : "")} style={{ "--bed": z.color, ...style }}>
      {dueToday(z) && <span className="beddue"><i className="ph-bold ph-drop"></i></span>}
      <div className="bedtop"><span className="bedname">{z.name}</span></div>
      <div className="bedcrops">
        {z.crops.slice(0, 3).map((c) => (
          <span className="cchip" key={c.name}><span className="cd" style={{ background: c.color }}></span>{c.name}</span>
        ))}
      </div>
    </div>
  );
}

function Legend() {
  return (
    <div className="legend">
      <span className="li"><span className="cd" style={{ background: "var(--c-warm)" }}></span>Fruits-légumes</span>
      <span className="li"><span className="cd" style={{ background: "var(--c-green-mid)" }}></span>Aromates</span>
      <span className="li"><span className="cd" style={{ background: "var(--c-aubergine)" }}></span>Sous serre</span>
      <span className="li"><i className="ph-bold ph-drop" style={{ color: "var(--c-warm)", fontSize: 12 }}></i>Tâche du jour</span>
    </div>
  );
}

function PHeaderTop() {
  return (
    <div className="pbar">
      <div>
        <div className="season"><i className="ph-fill ph-sun"></i>Saison · été</div>
        <h1>Mon potager</h1>
      </div>
      <div className="acts">
        <button className="ibtn" aria-label="Rechercher"><i className="ph ph-magnifying-glass"></i></button>
        <button className="ibtn" aria-label="Plus d'options"><i className="ph ph-dots-three-vertical"></i></button>
      </div>
    </div>
  );
}

function Shell({ label, children }) {
  return (
    <div className="phone" data-screen-label={label}>
      <div className="pstatus"><span>8:24</span><PDots /></div>
      <PHeaderTop />
      <div className="pscreen">{children}</div>
      <PNav />
    </div>
  );
}

// ── A · plan en grille (potager carré) ────────────────────────────────────
function PotagerGrille() {
  const order = ["serre", "nord", "sud", "aromates", "bordure"];
  return (
    <Shell label="Potager · A — Plan en grille">
      <div className="plan grid">
        <Bed z={byId("serre")} span />
        <Bed z={byId("nord")} />
        <Bed z={byId("sud")} />
        <Bed z={byId("aromates")} />
        <Bed z={byId("bordure")} />
      </div>
      <Legend />
    </Shell>
  );
}

// ── B · plan spatial (maquette du jardin) ─────────────────────────────────
function PotagerMap() {
  const pos = {
    serre:    { top: 9, left: 11, width: 144, height: 96 },
    aromates: { top: 9, right: 11, width: 144, height: 96 },
    nord:     { top: 117, left: 11, width: 144, height: 196 },
    sud:      { top: 117, right: 11, width: 144, height: 196 },
    bordure:  { bottom: 9, left: 11, right: 11, height: 64 },
  };
  return (
    <Shell label="Potager · B — Plan spatial">
      <div className="plan map">
        {Object.entries(pos).map(([id, st]) => <Bed key={id} z={byId(id)} style={st} />)}
      </div>
      <Legend />
    </Shell>
  );
}

// ── C · mini-plan + liste détaillée ───────────────────────────────────────
function PotagerListe() {
  return (
    <Shell label="Potager · C — Plan + liste">
      <div className="plan mini">
        <Bed z={byId("serre")} span />
        <Bed z={byId("nord")} />
        <Bed z={byId("sud")} />
        <Bed z={byId("aromates")} />
        <Bed z={byId("bordure")} />
      </div>
      <p className="slabel" style={{ marginTop: "var(--sp-1)" }}>Zones <span className="count">5</span></p>
      <div className="zonelist">
        {ZONES.map((z) => {
          const next = z.crops.find((c) => c.task !== "—") || z.crops[0];
          return (
            <div className="zrow" key={z.id} style={{ "--bed": z.color }}>
              <span className="zbar"></span>
              <div className="zmain">
                <span className="zname">{z.name}</span>
                <span className="zmeta">{z.crops.map((c) => c.name).join(" · ")}</span>
              </div>
              <span className={"ztask" + (dueToday(z) ? "" : " ok")}>{next.task === "—" ? "À jour" : next.task}</span>
              <i className="ph ph-caret-right chev"></i>
            </div>
          );
        })}
      </div>
    </Shell>
  );
}

// ── Détail d'une zone ─────────────────────────────────────────────────────
function ZoneDetail({ zoneId = "nord" }) {
  const z = byId(zoneId);
  return (
    <div className="phone" data-screen-label={"Potager · Détail — " + z.name}>
      <div className="pstatus"><span>8:24</span><PDots /></div>
      <div className="pbar back">
        <div style={{ display: "flex", alignItems: "center", gap: "var(--sp-3)", flex: 1, minWidth: 0 }}>
          <button className="backbtn" aria-label="Retour"><i className="ph-bold ph-caret-left"></i></button>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="season"><i className="ph-fill ph-sun"></i>{z.sun}</div>
            <h1>{z.name}</h1>
          </div>
        </div>
        <div className="acts"><button className="ibtn" aria-label="Plus"><i className="ph ph-dots-three-vertical"></i></button></div>
      </div>

      <div className="pscreen">
        <div className="zhero" style={{ "--bed": z.color }}>
          <div className="zinfo">
            <span className="ichip"><i className="ph ph-ruler"></i>{z.dims}</span>
            <span className="ichip"><i className="ph ph-drop"></i>{z.water}</span>
            <span className="ichip"><i className="ph ph-plant"></i>{z.crops.length} cultures</span>
          </div>
        </div>

        <p className="slabel">Cultures <span className="count">{z.crops.length}</span></p>
        <div className="block" style={{ gap: "var(--sp-3)" }}>
          {z.crops.map((c) => (
            <div className="culture" key={c.name}>
              <div className="ctop">
                <span className="cmark" style={{ background: c.color }}><i className={c.icon}></i></span>
                <div className="cnames">
                  <div className="cname">{c.name}</div>
                  <div className="cvar">{c.variete}</div>
                </div>
              </div>
              <div className="crow">
                <Stage n={c.stage} />
                <span className={"ctask" + (c.ok ? " ok" : "")}>
                  <i className={c.task === "—" ? "ph-fill ph-check-circle" : "ph-fill ph-bell-ringing"}></i>
                  {c.task === "—" ? "À jour · " + c.due : c.task + " · " + c.due}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <PNav />
    </div>
  );
}

Object.assign(window, { PotagerGrille, PotagerMap, PotagerListe, ZoneDetail });
