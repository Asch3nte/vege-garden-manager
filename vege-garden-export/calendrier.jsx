/* calendrier.jsx — écran « Calendrier » unifié du Carnet vivant.
   Une seule vue avec un sélecteur (Agenda · Mois · Saison) :
   • Agenda  — fil des tâches à faire, cochables (base = ancien traitement B)
   • Mois    — grille mensuelle ; on tape un jour → mêmes tâches cochables (A)
   • Saison  — calendrier semis → récolte sur l'année (C)
   Tâches typées par geste, rattachées à une zone du plan.
   Données : juin 2026, aujourd'hui = lundi 8.
   Export : CalendrierApp */

/* ── types de gestes (couleur + icône) ── */
const T = {
  semer:      { label: "Semer",      icon: "ph-fill ph-shovel",        color: "var(--c-green-mid)" },
  planter:    { label: "Planter",    icon: "ph-fill ph-plant",         color: "var(--c-primary)" },
  arroser:    { label: "Arroser",    icon: "ph-fill ph-drop",          color: "var(--c-info)" },
  tailler:    { label: "Tailler",    icon: "ph-fill ph-scissors",      color: "var(--c-ocre)" },
  tuteurer:   { label: "Tuteurer",   icon: "ph-fill ph-arrow-fat-up",  color: "var(--c-terre)" },
  surveiller: { label: "Surveiller", icon: "ph-fill ph-eye",           color: "var(--c-attention)" },
  recolter:   { label: "Récolter",   icon: "ph-fill ph-basket",        color: "var(--c-aubergine)" },
};
/* couleurs de zone (cf. potager.jsx) */
const Z = {
  nord:     { name: "Carré nord",  color: "var(--c-warm)" },
  serre:    { name: "Serre",       color: "var(--c-aubergine)" },
  sud:      { name: "Carré sud",   color: "var(--c-green-deep)" },
  aromates: { name: "Bac aromates",color: "var(--c-green-mid)" },
  bordure:  { name: "Bordure sud", color: "var(--c-bordeaux)" },
};

/* tâches du mois — clé = jour de juin 2026 */
const EVENTS = {
  8:  [ { t: "arroser", z: "nord", crop: "Tomate", v: "Cœur de bœuf" },
        { t: "arroser", z: "serre", crop: "Piment", v: "Doux long" },
        { t: "recolter", z: "bordure", crop: "Fraise", v: "Gariguette" } ],
  9:  [ { t: "tuteurer", z: "sud", crop: "Haricot", v: "Beurre nain" },
        { t: "tailler", z: "nord", crop: "Basilic", v: "Grand vert" } ],
  10: [ { t: "recolter", z: "serre", crop: "Aubergine", v: "Violette longue" } ],
  11: [ { t: "arroser", z: "nord", crop: "Tomate", v: "Cœur de bœuf" },
        { t: "surveiller", z: "sud", crop: "Courgette", v: "oïdium" } ],
  12: [ { t: "tailler", z: "aromates", crop: "Thym", v: "Citron" } ],
  13: [ { t: "semer", z: "sud", crop: "Radis", v: "De 18 jours" },
        { t: "arroser", z: "nord", crop: "Tomate", v: "Cœur de bœuf" } ],
  15: [ { t: "recolter", z: "bordure", crop: "Fraise", v: "Gariguette" },
        { t: "arroser", z: "serre", crop: "Aubergine", v: "Violette longue" } ],
  16: [ { t: "tuteurer", z: "nord", crop: "Tomate", v: "Cœur de bœuf" } ],
  18: [ { t: "recolter", z: "sud", crop: "Courgette", v: "Ronde de Nice" } ],
  20: [ { t: "semer", z: "sud", crop: "Mâche", v: "Verte de Cambrai" } ],
  21: [ { t: "arroser", z: "nord", crop: "Tout le potager", v: "" },
        { t: "tailler", z: "aromates", crop: "Romarin", v: "Officinal" } ],
  24: [ { t: "recolter", z: "serre", crop: "Aubergine", v: "Violette longue" } ],
  26: [ { t: "planter", z: "sud", crop: "Poireau", v: "Bleu de Solaise" } ],
  28: [ { t: "recolter", z: "bordure", crop: "Fraise", v: "Gariguette" } ],
  30: [ { t: "surveiller", z: "nord", crop: "Tomate", v: "mildiou" } ],
};

const WD = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
const WD1 = ["L", "M", "M", "J", "V", "S", "D"];
const TODAY = 8; // juin 2026 commence un lundi → lundi 8

const wkLabel = (d) => WD[(d - 1) % 7];
const dayWord = (d) => d === TODAY ? "Aujourd'hui" : d === TODAY + 1 ? "Demain" : wkLabel(d);
const keyOf = (d, i) => d + "-" + i;

/* ── chrome ── */
function PDots() {
  return <span className="dots"><i className="ph-fill ph-cell-signal-full"></i><i className="ph-fill ph-wifi-high"></i><i className="ph-fill ph-battery-high"></i></span>;
}
function PNav() {
  const items = [["house", "Accueil"], ["plant", "Potager"], ["book-open", "Catalogue"], ["calendar-blank", "Calendrier"], ["dots-three", "Plus"]];
  return (
    <div className="bnav">
      {items.map(([i, l]) => {
        const on = l === "Calendrier";
        return <div className={"nav" + (on ? " active" : "")} key={l}><i className={"ph" + (on ? "-fill" : "") + " ph-" + i}></i><span>{l}</span></div>;
      })}
    </div>
  );
}

/* carte de tâche unifiée — cochable (utilisée en Agenda ET en Mois) */
function TaskCard({ d, i, e, done, onToggle }) {
  const ty = T[e.t], z = Z[e.z];
  const isDone = !!done[keyOf(d, i)];
  return (
    <button type="button" className={"taskcard" + (isDone ? " is-done" : "")} onClick={() => onToggle(d, i)}>
      <span className="tc-ic" style={{ background: ty.color }}><i className={ty.icon}></i></span>
      <span className="tc-main">
        <span className="tc-task">{ty.label} — {e.crop}</span>
        <span className="tc-meta">
          <span className="zdot" style={{ background: z.color }}></span>{z.name}
          {e.v ? <span className="var"> · {e.v}</span> : null}
        </span>
      </span>
      <span className={"tc-check" + (isDone ? " done" : "")} aria-hidden="true"><i className="ph-bold ph-check"></i></span>
    </button>
  );
}

/* sélecteur de vue */
function ViewSwitch({ view, setView }) {
  const tabs = [
    ["agenda", "Agenda", "ph-list-checks"],
    ["mois", "Mois", "ph-calendar-dots"],
    ["saison", "Saison", "ph-plant"],
  ];
  return (
    <div className="viewswitch" role="tablist">
      {tabs.map(([id, lab, ic]) => (
        <button key={id} type="button" role="tab" aria-selected={view === id}
          className={"vs-btn" + (view === id ? " on" : "")} onClick={() => setView(id)}>
          <i className={"ph" + (view === id ? "-fill" : "") + " " + ic}></i>{lab}
        </button>
      ))}
    </div>
  );
}

/* ── AGENDA ── */
function AgendaView({ scope, done, onToggle }) {
  const last = scope === "semaine" ? 14 : 30;
  const days = Object.keys(EVENTS).map(Number).filter((d) => d >= TODAY && d <= last).sort((a, b) => a - b);
  const weekTotal = [8, 9, 10, 11, 12, 13, 14].reduce((n, d) => n + (EVENTS[d] ? EVENTS[d].length : 0), 0);
  const doneCount = days.reduce((n, d) => n + EVENTS[d].filter((_, i) => done[keyOf(d, i)]).length, 0);
  const total = days.reduce((n, d) => n + EVENTS[d].length, 0);
  return (
    <>
      <div className="summ">
        <span className="summ-ring" style={{ "--p": total ? (doneCount / total) * 100 : 0 }}>
          <b>{doneCount}/{total}</b>
        </span>
        <div className="st">
          <b>{total - doneCount} tâche{total - doneCount > 1 ? "s" : ""}</b> à faire
          {scope === "semaine" ? " cette semaine" : " ce mois-ci"}.
          <span className="st-sub">{weekTotal} prévues sur 7 jours.</span>
        </div>
      </div>

      <div className="timeline">
        {days.map((d) => (
          <div className="tlgroup" key={d}>
            <div className="tlhead">
              <span className={"th-day" + (d === TODAY ? " now" : "")}>{dayWord(d)}</span>
              <span className="th-rest">{d} juin</span>
              <span className="th-line"></span>
            </div>
            {EVENTS[d].map((e, i) => <TaskCard key={i} d={d} i={i} e={e} done={done} onToggle={onToggle} />)}
          </div>
        ))}
      </div>
    </>
  );
}

/* ── MOIS ── */
function MoisView({ selected, setSelected, done, onToggle }) {
  const cells = [];
  for (let d = 1; d <= 30; d++) cells.push(d);
  const trailing = (7 - (cells.length % 7)) % 7;
  const sel = EVENTS[selected] || [];
  const dayLabel = (selected === TODAY ? "Aujourd'hui · " : wkLabel(selected) + " ") + selected + " juin";
  return (
    <>
      <div className="monthbar">
        <div className="monthnav">
          <button className="marrow" aria-label="Mois précédent"><i className="ph-bold ph-caret-left"></i></button>
          <span className="mlabel">Juin 2026</span>
          <button className="marrow" aria-label="Mois suivant"><i className="ph-bold ph-caret-right"></i></button>
        </div>
        <button type="button" className="todaypill" onClick={() => setSelected(TODAY)}><i className="ph-fill ph-circle"></i>Aujourd'hui</button>
      </div>

      <div className="calgrid">
        <div className="wkhead">{WD.map((d, i) => <span key={i}>{d}</span>)}</div>
        <div className="days">
          {cells.map((d) => {
            const ev = EVENTS[d] || [];
            const allDone = ev.length > 0 && ev.every((_, i) => done[keyOf(d, i)]);
            const cls = "day" + (d === TODAY ? " today" : "") + (d === selected ? " sel" : "") + (allDone ? " alldone" : "");
            return (
              <button type="button" className={cls} key={d} onClick={() => setSelected(d)}>
                <span className="dnum">{d}</span>
                <span className="dots">
                  {allDone ? <i className="chk ph-bold ph-check"></i> :
                    <>{ev.slice(0, 3).map((e, i) => <i key={i} style={{ background: T[e.t].color }}></i>)}
                    {ev.length > 3 && <span className="more">+{ev.length - 3}</span>}</>}
                </span>
              </button>
            );
          })}
          {Array.from({ length: trailing }).map((_, i) => (
            <div className="day out" key={"t" + i}><span className="dnum">{i + 1}</span><span className="dots"></span></div>
          ))}
        </div>
      </div>

      <div className="agday">
        <span className="ad-date">{dayLabel}</span>
        {sel.length > 0 && <span className="ad-count">{sel.filter((_, i) => done[keyOf(selected, i)]).length}/{sel.length}</span>}
      </div>

      {sel.length > 0 ? (
        <div className="agenda">{sel.map((e, i) => <TaskCard key={i} d={selected} i={i} e={e} done={done} onToggle={onToggle} />)}</div>
      ) : (
        <div className="agempty"><i className="ph-duotone ph-coffee"></i><span>Rien de prévu — profitez du jardin.</span></div>
      )}
    </>
  );
}

/* ── SAISON ── */
const SEASON = [
  { crop: "Tomate",    v: "Cœur de bœuf", bands: [["semis", 2, 3], ["plant", 4, 4], ["recolte", 6, 9]] },
  { crop: "Aubergine", v: "Violette",     bands: [["semis", 1, 2], ["plant", 4, 4], ["recolte", 6, 9]] },
  { crop: "Courgette", v: "Ronde de Nice",bands: [["semis", 3, 3], ["plant", 4, 4], ["recolte", 5, 8]] },
  { crop: "Haricot",   v: "Beurre nain",  bands: [["semis", 4, 6], ["recolte", 6, 9]] },
  { crop: "Basilic",   v: "Grand vert",   bands: [["semis", 2, 4], ["recolte", 5, 9]] },
  { crop: "Fraise",    v: "Gariguette",   bands: [["recolte", 4, 6], ["plant", 8, 8]] },
  { crop: "Radis",     v: "18 jours",     bands: [["semis", 2, 8], ["recolte", 3, 9]] },
  { crop: "Mâche",     v: "Cambrai",      bands: [["semis", 7, 8], ["recolte", 9, 11]] },
];
const MLET = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];
const NOW_M = 5; // juin (index 0-based)

function SaisonView() {
  return (
    <>
      <p className="sectlabel"><i className="ph-fill ph-leaf"></i>Du semis à la récolte</p>
      <div className="seasonwrap">
        <div className="sw-head">
          <span className="corner">Culture</span>
          <div className="sw-months">{MLET.map((m, i) => <span key={i} className={i === NOW_M ? "on" : ""}>{m}</span>)}</div>
        </div>
        {SEASON.map((r) => (
          <div className="srow" key={r.crop}>
            <span className="croplab">{r.crop}<small>{r.v}</small></span>
            <div className="track">
              <span className="nowband" style={{ gridColumn: (NOW_M + 1) + " / " + (NOW_M + 2) }}></span>
              {r.bands.map((b, i) => (
                <span className={"sband " + b[0]} key={i} style={{ gridColumn: (b[1] + 1) + " / " + (b[2] + 2) }}></span>
              ))}
            </div>
          </div>
        ))}
      </div>
      <div className="seasonleg">
        <span className="li"><span className="bar semis"></span>Semis</span>
        <span className="li"><span className="bar plant"></span>Plantation</span>
        <span className="li"><span className="bar recolte"></span>Récolte</span>
        <span className="li"><span className="bar now"></span>Ce mois-ci</span>
      </div>
    </>
  );
}

/* ── App ── */
function CalendrierApp({ startView = "agenda", agendaScope = "semaine" }) {
  const [view, setView] = React.useState(startView);
  const [selected, setSelected] = React.useState(9);
  const [done, setDone] = React.useState({ "8-2": true }); // récolte fraises déjà faite

  // suivre le tweak « vue par défaut » quand il change
  React.useEffect(() => { setView(startView); }, [startView]);

  const toggle = (d, i) => setDone((prev) => {
    const k = keyOf(d, i), next = { ...prev };
    if (next[k]) delete next[k]; else next[k] = true;
    return next;
  });

  return (
    <div className="phone" data-screen-label="Calendrier">
      <div className="pstatus"><span>8:24</span><PDots /></div>
      <div className="pbar">
        <div>
          <div className="season"><i className="ph-fill ph-sun"></i>Saison · été</div>
          <h1>Calendrier</h1>
        </div>
        <div className="acts">
          <button className="ibtn" aria-label="Filtrer"><i className="ph ph-funnel"></i></button>
          <button className="ibtn" aria-label="Ajouter une tâche"><i className="ph ph-plus"></i></button>
        </div>
      </div>

      <ViewSwitch view={view} setView={setView} />

      <div className="pscreen calscreen" key={view}>
        {view === "agenda" && <AgendaView scope={agendaScope} done={done} onToggle={toggle} />}
        {view === "mois" && <MoisView selected={selected} setSelected={setSelected} done={done} onToggle={toggle} />}
        {view === "saison" && <SaisonView />}
      </div>

      <PNav />
    </div>
  );
}

Object.assign(window, { CalendrierApp });
