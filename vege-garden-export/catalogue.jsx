/* catalogue.jsx — écran « Catalogue » du Carnet vivant.
   Vue Fiches (recherche + filtres + cartes) · Vue Réseau (constellation
   d'associations) · Fiche détaillée en overlay.
   Dépend de catalogue-data.jsx (CATS, PLANTS, plantById, plantMatches, goodEdges).
   Export : CatalogueApp */

const MLET = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];

/* ── chrome ── */
function PDots() {
  return <span className="dots"><i className="ph-fill ph-cell-signal-full"></i><i className="ph-fill ph-wifi-high"></i><i className="ph-fill ph-battery-high"></i></span>;
}
function PNav() {
  const items = [["house", "Accueil"], ["plant", "Potager"], ["book-open", "Catalogue"], ["calendar-blank", "Calendrier"], ["dots-three", "Plus"]];
  return (
    <div className="bnav">
      {items.map(([i, l]) => {
        const on = l === "Catalogue";
        return <div className={"nav" + (on ? " active" : "")} key={l}><i className={"ph" + (on ? "-fill" : "") + " ph-" + i}></i><span>{l}</span></div>;
      })}
    </div>
  );
}
const diffDots = (n) => [1, 2, 3].map((i) => <i key={i} className={i <= n ? "on" : ""}></i>);

/* ── carte plante ── */
function PlantCard({ p, onOpen }) {
  const c = CATS[p.cat];
  return (
    <button type="button" className="pcard" style={{ "--pc": c.color }} onClick={() => onOpen(p.id)}>
      <span className="pc-top">
        <span className="pc-diff">{diffDots(p.diff)}</span>
        <span className="pc-ic"><i className={p.icon}></i></span>
      </span>
      <span className="pc-body">
        <span className="pc-name">{p.name}</span>
        <span className="pc-var">{p.varietes.length} variétés</span>
        <span className="pc-meta">
          <span><i className="ph ph-sun"></i>{p.expo}</span>
          <span><i className="ph ph-drop"></i>{p.eau}</span>
        </span>
      </span>
    </button>
  );
}

/* ── VUE FICHES ── */
function FichesView({ query, cat, onOpen }) {
  const filtered = PLANTS.filter((p) => (cat === "tout" || p.cat === cat) && plantMatches(p, query));
  if (!filtered.length) {
    return <div className="catempty"><i className="ph-duotone ph-magnifying-glass"></i><span>Aucune plante ne correspond.<br />Essaie un autre mot ou une autre catégorie.</span></div>;
  }
  // groupé en carrousels par catégorie quand on parcourt « Tout » sans recherche ; sinon grille
  const grouped = cat === "tout" && !query.trim();
  if (grouped) {
    return (
      <>
        {CAT_ORDER.map((id) => {
          const list = filtered.filter((p) => p.cat === id);
          if (!list.length) return null;
          const c = CATS[id];
          return (
            <div className="catsec" key={id}>
              <div className="catsec-h">
                <span className="ttl"><span className="fdot" style={{ background: c.color }}></span>{c.label}</span>
                <span className="cnt">{list.length}</span>
              </div>
              <div className="carou">{list.map((p) => <PlantCard key={p.id} p={p} onOpen={onOpen} />)}</div>
            </div>
          );
        })}
      </>
    );
  }
  return <div className="pgrid">{filtered.map((p) => <PlantCard key={p.id} p={p} onOpen={onOpen} />)}</div>;
}

/* ── VUE RÉSEAU ── */
const CX = 156, CY = 172, VB_H = 360, MAXR = 116;
function useLayout() {
  return React.useMemo(() => {
    const pos = {};
    const n = PLANTS.length;
    const GA = Math.PI * (3 - Math.sqrt(5)); // angle d'or → distribution régulière
    PLANTS.forEach((p, i) => {
      const r = MAXR * Math.sqrt((i + 0.5) / n);
      const ang = i * GA - Math.PI / 2;
      pos[p.id] = { x: CX + Math.cos(ang) * r, y: CY + Math.sin(ang) * r };
    });
    return pos;
  }, []);
}

function ReseauView({ query, cat, sel, setSel, showBad, onOpen }) {
  const pos = useLayout();
  const edges = React.useMemo(() => goodEdges().filter((e) => e.type === "good" || showBad), [showBad]);
  const passes = (p) => (cat === "tout" || p.cat === cat) && plantMatches(p, query);
  const selP = sel ? plantById(sel) : null;
  const linked = React.useMemo(() => {
    if (!sel) return new Set();
    const s = new Set();
    edges.forEach((e) => { if (e.a === sel) s.add(e.b); if (e.b === sel) s.add(e.a); });
    return s;
  }, [sel, edges]);

  const nodeState = (p) => {
    if (sel) return (p.id === sel ? "sel" : linked.has(p.id) ? "linked" : "dim");
    if (query.trim() || cat !== "tout") return passes(p) ? "" : "dim";
    return "";
  };

  return (
    <div className="greseau">
      <div className="gcanvas" onClick={(e) => { if (!e.target.closest(".gnode") && !e.target.closest(".gpanel")) setSel(null); }}>
        <div className="gstars"></div>
        <svg viewBox={"0 0 312 " + VB_H} preserveAspectRatio="none">
          {edges.map((e, i) => {
            const a = pos[e.a], b = pos[e.b];
            if (!a || !b) return null;
            let cls = "gedge" + (e.type === "bad" ? " bad" : "");
            if (sel) cls += (e.a === sel || e.b === sel) ? " hot" : " cold";
            return <line key={i} x1={a.x} y1={a.y} x2={b.x} y2={b.y} className={cls} />;
          })}
        </svg>
        {PLANTS.map((p) => {
          const st = nodeState(p);
          return (
            <button type="button" key={p.id} className={"gnode" + (st ? " " + st : "")}
              style={{ left: pos[p.id].x, top: pos[p.id].y, "--pc": CATS[p.cat].color }}
              onClick={(ev) => { ev.stopPropagation(); sel === p.id ? onOpen(p.id) : setSel(p.id); }}>
              <span className="gn-dot"><i className={p.icon}></i></span>
              <span className="gn-lab">{p.name}</span>
            </button>
          );
        })}
        {selP ? (
          <div className="gpanel" style={{ "--pc": CATS[selP.cat].color }} onClick={(e) => e.stopPropagation()}>
            <span className="gp-ic"><i className={selP.icon}></i></span>
            <div className="gp-main">
              <div className="gp-name">{selP.name}</div>
              <div className="gp-meta">
                <span><b>{selP.good.length}</b> bons compagnons</span>
                {selP.bad.length > 0 && <span><b className="bad">{selP.bad.length}</b> à éviter</span>}
              </div>
            </div>
            <button type="button" className="gp-go" onClick={() => onOpen(selP.id)}>Fiche<i className="ph-bold ph-arrow-right"></i></button>
          </div>
        ) : (
          <div className="ghint">Touche une plante pour voir ses associations</div>
        )}
      </div>

      <div className="gleg">
        <span className="li"><span className="ln"></span>Bon compagnon</span>
        {showBad && <span className="li"><span className="ln bad"></span>À éviter</span>}
        <span className="li"><i className="ph-fill ph-circle" style={{ color: "var(--c-warm)", fontSize: 9 }}></i>couleur = catégorie</span>
      </div>
    </div>
  );
}

/* ── FICHE DÉTAILLÉE ── */
function MonthStrip({ range, kind }) {
  return (
    <div className="ftrack">
      <span className={"sband " + kind} style={{ gridColumn: (range[0] + 1) + " / " + (range[1] + 2) }}></span>
    </div>
  );
}
function FicheDetail({ id, onClose, onOpen }) {
  const p = plantById(id);
  const c = CATS[p.cat];
  const ref = React.useRef(null);
  React.useEffect(() => { if (ref.current) ref.current.scrollTop = 0; }, [id]);
  const facts = [
    ["ph-sun", "Exposition", p.expo],
    ["ph-drop", "Arrosage", p.eau],
    ["ph-mountains", "Sol", p.sol],
    ["ph-arrows-out-line-vertical", "Gabarit", p.haut],
    ["ph-arrows-out-line-horizontal", "Espacement", p.espace],
    ["ph-gauge", "Difficulté", DIFF[p.diff]],
  ];
  return (
    <div className="fiche" style={{ "--pc": c.color }}>
      <div className="f-hero">
        <div className="f-bar">
          <button type="button" className="f-back" onClick={onClose} aria-label="Retour"><i className="ph-bold ph-caret-left"></i></button>
          <button type="button" className="f-x" onClick={onClose} aria-label="Fermer"><i className="ph ph-x"></i></button>
        </div>
        <div className="f-id">
          <span className="f-ic"><i className={p.icon}></i></span>
          <div className="f-tt">
            <h2>{p.name}</h2>
            <span className="f-cat"><span className="fdot" style={{ background: c.color }}></span>{c.label}</span>
          </div>
        </div>
      </div>

      <div className="f-body" ref={ref}>
        <p className="f-desc">{p.desc}</p>

        <div className="f-facts">
          {facts.map(([ic, k, v]) => (
            <div className="f-fact" key={k}><i className={"ph " + ic}></i><div className="ft"><div className="k">{k}</div><div className="v">{v}</div></div></div>
          ))}
        </div>

        <div>
          <p className="f-lab"><i className="ph-fill ph-calendar-dots"></i>Semis & récolte</p>
          <div className="fcal">
            <div className="fcal-m">{MLET.map((m, i) => <span key={i}>{m}</span>)}</div>
            <MonthStrip range={p.semis} kind="semis" />
            <MonthStrip range={p.recolte} kind="recolte" />
            <div className="fcal-leg">
              <span className="li"><span className="bar semis"></span>Semis</span>
              <span className="li"><span className="bar recolte"></span>Récolte</span>
            </div>
          </div>
        </div>

        <div>
          <p className="f-lab"><i className="ph-fill ph-list-bullets"></i>Variétés <span style={{ color: "var(--c-ink-2)", fontWeight: 600 }}>· {p.varietes.length}</span></p>
          <div className="fvars">{p.varietes.map((v) => <span className="vchip" key={v}>{v}</span>)}</div>
        </div>

        <div>
          <p className="f-lab"><i className="ph-fill ph-handshake"></i>Associations</p>
          <div className="fcomp">
            <div className="crow">
              {p.good.length ? p.good.map((gid) => {
                const g = plantById(gid); if (!g) return null;
                return <button type="button" className="ctag good" key={gid} onClick={() => onOpen(gid)}><span className="cdot" style={{ background: CATS[g.cat].color }}><i className={g.icon}></i></span>{g.name}</button>;
              }) : <span className="none">—</span>}
            </div>
            {p.bad.length > 0 && (
              <div className="crow" style={{ marginTop: 4 }}>
                <span style={{ fontSize: 11, fontWeight: 700, color: "var(--c-bordeaux)", display: "inline-flex", alignItems: "center", gap: 4 }}><i className="ph-bold ph-prohibit"></i>À éviter :</span>
                {p.bad.map((bid) => {
                  const g = plantById(bid); if (!g) return null;
                  return <button type="button" className="ctag avoid" key={bid} onClick={() => onOpen(bid)}><span className="cdot" style={{ background: CATS[g.cat].color }}><i className={g.icon}></i></span>{g.name}</button>;
                })}
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="f-foot">
        <button type="button" className="f-add"><i className="ph-bold ph-plus"></i>Ajouter au potager</button>
      </div>
    </div>
  );
}

/* ── App ── */
function CatalogueApp({ startView = "fiches", showBad = true }) {
  const [view, setView] = React.useState(startView);
  const [query, setQuery] = React.useState("");
  const [cat, setCat] = React.useState("tout");
  const [sel, setSel] = React.useState(null);
  const [fiche, setFiche] = React.useState(null);

  React.useEffect(() => { setView(startView); }, [startView]);

  const openFiche = (id) => setFiche(id);
  const chips = [["tout", "Tout", null], ...CAT_ORDER.map((id) => [id, CATS[id].label, CATS[id].color])];

  return (
    <div className="phone" data-screen-label="Catalogue">
      <div className="pstatus"><span>8:24</span><PDots /></div>
      <div className="pbar">
        <div>
          <div className="season"><i className="ph-fill ph-book-open"></i>{PLANTS.length} plantes</div>
          <h1>Catalogue</h1>
        </div>
        <div className="acts">
          <button className="ibtn" aria-label="Favoris"><i className="ph ph-heart"></i></button>
        </div>
      </div>

      <div className="csearch">
        <i className="ph ph-magnifying-glass"></i>
        <input value={query} onChange={(e) => { setQuery(e.target.value); setSel(null); }}
          placeholder="Nom, sol, exposition, association…" aria-label="Rechercher une plante" />
        {query && <button className="clr" onClick={() => setQuery("")} aria-label="Effacer"><i className="ph-bold ph-x"></i></button>}
      </div>

      <div className="cchips">
        {chips.map(([id, lab, color]) => (
          <button key={id} type="button" className={"fchip" + (cat === id ? " on" : "")} onClick={() => { setCat(id); setSel(null); }}>
            {color && <span className="fdot" style={{ background: color }}></span>}{lab}
          </button>
        ))}
      </div>

      <div className="viewswitch" role="tablist">
        <button type="button" role="tab" aria-selected={view === "fiches"} className={"vs-btn" + (view === "fiches" ? " on" : "")} onClick={() => setView("fiches")}><i className={"ph" + (view === "fiches" ? "-fill" : "") + " ph-squares-four"}></i>Fiches</button>
        <button type="button" role="tab" aria-selected={view === "reseau"} className={"vs-btn" + (view === "reseau" ? " on" : "")} onClick={() => setView("reseau")}><i className={"ph" + (view === "reseau" ? "-fill" : "") + " ph-graph"}></i>Réseau</button>
      </div>

      <div className="pscreen catscreen" key={view}>
        {view === "fiches"
          ? <FichesView query={query} cat={cat} onOpen={openFiche} />
          : <ReseauView query={query} cat={cat} sel={sel} setSel={setSel} showBad={showBad} onOpen={openFiche} />}
      </div>

      <PNav />

      {fiche && <FicheDetail id={fiche} onClose={() => setFiche(null)} onOpen={openFiche} />}
    </div>
  );
}

Object.assign(window, { CatalogueApp });
