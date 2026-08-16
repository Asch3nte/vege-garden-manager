/* aromates-grimpantes.jsx — Parcelles, version « aromates + grimpante »
   Tapis d'herbes aromatiques fines (romarin/thym/origan) traversé par une
   ou deux plantes grimpantes (vigne) qui montent jusqu'en haut.
   Réutilise .phone[data-variant="t2"] de bg-directions.css */

// ── briques UI ──────────────────────────────────────────────────────────
function Dots() {
  return <span className="dots"><i className="ph-fill ph-cell-signal-full"></i><i className="ph-fill ph-wifi-high"></i><i className="ph-fill ph-battery-high"></i></span>;
}
function Weather() {
  return (
    <div className="weather">
      <i className="ph-duotone ph-cloud-sun"></i>
      <div><div className="temp">18°</div><div className="sub">Partiellement nuageux</div></div>
      <span className="spacer"></span>
      <div className="ok"><b>Bon pour arroser</b><span>Pluie demain</span></div>
    </div>
  );
}
function Tasks() {
  return (
    <div className="card">
      <div className="task"><span className="check"></span><span className="tx"><span className="lab">Arroser les tomates</span></span><span className="tag sage">Carré nord</span></div>
      <div className="task"><span className="check"></span><span className="tx"><span className="lab">Semer les radis</span></span><span className="tag warm">Bac aromates</span></div>
      <div className="task"><span className="check"></span><span className="tx"><span className="lab">Récolter les aubergines</span></span><span className="tag harvest">À maturité</span></div>
    </div>
  );
}
function Nav() {
  return (
    <div className="bnav">
      <div className="nav active"><i className="ph-fill ph-house"></i><span>Accueil</span></div>
      <div className="nav"><i className="ph ph-plant"></i><span>Potager</span></div>
      <div className="nav"><i className="ph ph-book-open"></i><span>Catalogue</span></div>
      <div className="nav"><i className="ph ph-calendar-blank"></i><span>Calendrier</span></div>
      <div className="nav"><i className="ph ph-dots-three"></i><span>Plus</span></div>
    </div>
  );
}

// ── feuilles ────────────────────────────────────────────────────────────
const LEAF = "M0 0 C -10 -10, -8 -30, 0 -42 C 8 -30, 10 -10, 0 0 Z";       // petite feuille fine
const LOBED = "M0 0 C -19 -5 -27 -22 -22 -37 C -11 -31 -7 -35 0 -48 C 7 -35 11 -31 22 -37 C 27 -22 19 -5 0 0 Z"; // feuille lobée (vigne)

// brin d'aromatique : tige + petites feuilles alternées
function HerbSprig({ x = 0, h = 120, lean = 0, leaf = 0.5, color = "currentColor", needles = false }) {
  const n = Math.round(h / 12);
  const items = [];
  for (let i = 1; i <= n; i++) {
    const t = i / (n + 1);
    const y = -h * t;
    const side = i % 2 === 0 ? 1 : -1;
    if (needles) {
      // romarin : aiguilles (traits courts)
      const len = 9 * (1 - t * 0.5);
      items.push(<line key={i} x1="0" y1={y} x2={side * len} y2={y - 5} stroke={color} strokeWidth="1.6" strokeLinecap="round" />);
      items.push(<line key={i + "b"} x1="0" y1={y} x2={side * -len * 0.5} y2={y - 4} stroke={color} strokeWidth="1.6" strokeLinecap="round" />);
    } else {
      const s = leaf * (1 - t * 0.4);
      items.push(<g key={i} transform={`translate(0 ${y}) rotate(${side * 52}) scale(${s})`}><path d={LEAF} fill={color} /></g>);
    }
  }
  // feuille / pointe au sommet
  items.push(<g key="tip" transform={`translate(0 ${-h}) scale(${leaf})`}><path d={LEAF} fill={color} /></g>);
  return (
    <g transform={`translate(${x} 0) rotate(${lean})`}>
      <path d={`M0 0 C ${lean * 0.4} ${-h * 0.4} ${-lean * 0.3} ${-h * 0.7} 0 ${-h}`} stroke={color} strokeWidth="1.8" fill="none" strokeLinecap="round" />
      {items}
    </g>
  );
}

// touffe d'aromatiques (plusieurs brins)
function HerbTuft({ color, opacity, sprigs, needles = false }) {
  return (
    <svg viewBox="0 0 160 150" width="100%" height="100%" aria-hidden="true" style={{ color, opacity }}>
      <g transform="translate(80 150)">
        {sprigs.map((s, i) => <HerbSprig key={i} {...s} needles={needles} />)}
      </g>
    </svg>
  );
}

function Tendril({ x, y, flip = 1 }) {
  return <path transform={`translate(${x} ${y}) scale(${flip} 1)`} d="M0 0 C 10 -3 14 6 7 9 C 2 11 0 5 4 3" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />;
}

// feuilles des grimpantes selon le type
const HEART = "M0 0 C -17 -8 -21 -28 -9 -40 C -4 -35 -2 -38 0 -46 C 2 -38 4 -35 9 -40 C 21 -28 17 -8 0 0 Z"; // haricot
function ClimberLeaf({ type }) {
  if (type === "capucine") return <g><circle r="15" fill="currentColor" />{[0,1,2,3,4,5].map(a => <path key={a} d="M0 0 L0 -14" transform={`rotate(${a*60})`} stroke="var(--c-bg)" strokeWidth="1.3" strokeOpacity=".4" />)}</g>;
  if (type === "haricot") return <g><path d={HEART} fill="currentColor" /><path d="M0 -3 L0 -38" stroke="var(--c-bg)" strokeWidth="1.5" strokeOpacity=".4" /></g>;
  return <g><path d={LOBED} fill="currentColor" /><path d="M0 -4 L0 -40" stroke="var(--c-bg)" strokeWidth="1.6" strokeOpacity=".4" /></g>; // vigne
}

// petite fleur 5 pétales (haricot / capucine)
function Blossom({ x, y, s = 1, color }) {
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      {[0,72,144,216,288].map(a => <ellipse key={a} cx="0" cy="-5.5" rx="3" ry="5.5" transform={`rotate(${a})`} fill={color} />)}
      <circle r="2.4" fill="var(--c-ocre)" />
    </g>
  );
}

// grimpante générique : tige montante, feuilles selon type, vrilles, fleurs option.
function Climber({ color, opacity, paleTop, type = "vigne", flower = null }) {
  const stem = "M150 540 C 96 470 150 430 110 360 C 78 300 130 250 96 184 C 70 132 110 96 84 36 C 76 18 84 6 70 -8";
  const leaves = [
    { x: 120, y: 470, r: -120, s: 1.0 },
    { x: 110, y: 360, r: -150, s: 1.05 },
    { x: 118, y: 300, r: -70, s: .9 },
    { x: 96, y: 230, r: -135, s: 1.0 },
    { x: 110, y: 184, r: -60, s: .92 },
    { x: 86, y: 120, r: -140, s: .95 },
    { x: 96, y: 70, r: -70, s: .85 },
  ];
  const pale = [
    { x: 80, y: 26, r: -130, s: .8 },
    { x: 70, y: -10, r: -60, s: .72 },
  ];
  const blossomAt = [{ x: 128, y: 420, s: 1 }, { x: 100, y: 270, s: .92 }, { x: 112, y: 150, s: .86 }];
  return (
    <svg viewBox="0 0 170 560" width="100%" height="100%" aria-hidden="true">
      <g style={{ color, opacity }}>
        <path d={stem} fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
        {leaves.map((l, i) => <g key={i} transform={`translate(${l.x} ${l.y}) rotate(${l.r}) scale(${l.s})`}><ClimberLeaf type={type} /></g>)}
        <g style={{ color }}><Tendril x={128} y={410} flip={1} /><Tendril x={104} y={260} flip={-1} /><Tendril x={96} y={150} flip={1} /></g>
      </g>
      {flower && <g style={{ opacity: Math.min(1, opacity + .45) }}>{blossomAt.map((b, i) => <Blossom key={i} {...b} color={flower} />)}</g>}
      {paleTop && (
        <g style={{ color: paleTop, opacity: .5 }}>
          {pale.map((l, i) => <g key={i} transform={`translate(${l.x} ${l.y}) rotate(${l.r}) scale(${l.s})`}><ClimberLeaf type={type} /></g>)}
          <Tendril x={70} y={6} flip={1} />
        </g>
      )}
    </svg>
  );
}
// alias rétro-compat
function Vine(props) { return <Climber {...props} />; }

// ── scène combinée ──────────────────────────────────────────────────────
// mapping nom de couleur (token) → variante claire pour le haut (en-tête vert)
const PALE_BY = {
  "var(--c-aubergine)": "var(--c-aubergine-2)",
  "var(--c-green-mid)": "var(--c-primary-2)",
  "var(--c-bordeaux)": "#D69AA0",
  "var(--c-ocre)": "#F0D08A",
  "var(--c-terre)": "#D9B48F",
};

// tapis d'aromatiques selon la densité
function buildTufts(density) {
  const base = [
    { pos: { left: "-30px", bottom: "-12px", width: "150px", height: "120px" }, color: "var(--c-primary)", opacity: .42, needles: false, sprigs: [{ x: -34, h: 96, lean: -16, leaf: .5 }, { x: -10, h: 116, lean: -4, leaf: .52 }, { x: 16, h: 100, lean: 12, leaf: .48 }, { x: 38, h: 80, lean: 22, leaf: .44 }] },
    { pos: { left: "78px", bottom: "-14px", width: "130px", height: "150px" }, color: "var(--c-green-deep)", opacity: .4, needles: true, sprigs: [{ x: -28, h: 128, lean: -12 }, { x: -4, h: 150, lean: -2 }, { x: 20, h: 132, lean: 12 }, { x: 40, h: 108, lean: 22 }] },
    { pos: { left: "150px", bottom: "-12px", width: "140px", height: "110px" }, color: "var(--c-ocre)", opacity: .42, needles: false, sprigs: [{ x: -30, h: 88, lean: -18, leaf: .5 }, { x: -6, h: 104, lean: -4, leaf: .54 }, { x: 18, h: 92, lean: 14, leaf: .48 }, { x: 40, h: 72, lean: 24, leaf: .42 }] },
    { pos: { right: "30px", bottom: "-12px", width: "120px", height: "130px" }, color: "var(--c-green-mid)", opacity: .36, needles: true, sprigs: [{ x: -22, h: 110, lean: -10 }, { x: 2, h: 132, lean: 2 }, { x: 24, h: 112, lean: 14 }] },
  ];
  // brins comblant les creux (densité augmentée)
  const fillA = [
    { pos: { left: "34px", bottom: "-13px", width: "120px", height: "100px" }, color: "var(--c-green-mid)", opacity: .34, needles: false, sprigs: [{ x: -18, h: 70, lean: -14, leaf: .46 }, { x: 4, h: 86, lean: 2, leaf: .5 }, { x: 26, h: 74, lean: 16, leaf: .44 }] },
    { pos: { left: "118px", bottom: "-12px", width: "120px", height: "120px" }, color: "var(--c-primary)", opacity: .36, needles: true, sprigs: [{ x: -16, h: 96, lean: -8 }, { x: 6, h: 116, lean: 4 }, { x: 26, h: 98, lean: 16 }] },
    { pos: { right: "-12px", bottom: "-13px", width: "110px", height: "110px" }, color: "var(--c-ocre)", opacity: .34, needles: false, sprigs: [{ x: -16, h: 78, lean: -12, leaf: .48 }, { x: 6, h: 92, lean: 4, leaf: .5 }, { x: 26, h: 76, lean: 16, leaf: .42 }] },
  ];
  const fillB = [
    { pos: { right: "-12px", bottom: "-13px", width: "110px", height: "104px" }, color: "var(--c-green-deep)", opacity: .3, needles: true, sprigs: [{ x: -14, h: 80, lean: -10 }, { x: 6, h: 98, lean: 4 }] },
    { pos: { right: "52px", bottom: "-13px", width: "110px", height: "100px" }, color: "var(--c-primary)", opacity: .34, needles: false, sprigs: [{ x: -16, h: 74, lean: -14, leaf: .46 }, { x: 6, h: 90, lean: 2, leaf: .5 }, { x: 26, h: 76, lean: 16, leaf: .42 }] },
    { pos: { right: "112px", bottom: "-13px", width: "100px", height: "108px" }, color: "var(--c-green-mid)", opacity: .32, needles: true, sprigs: [{ x: -12, h: 92, lean: -8 }, { x: 8, h: 108, lean: 6 }] },
  ];
  if (density === "luxuriant") return [...base, ...fillA, ...fillB];
  if (density === "normal") return base;
  return [...base, ...fillA]; // "dense" (défaut)
}

function SceneAromates({ density = "dense", climbers = [] }) {
  const tufts = buildTufts(density);
  return (
    <div className="field plants">
      <div className="arch"></div>
      <div className="soil"></div>

      {climbers.map((c, i) => {
        const right = c.side === "right";
        const W = 150;
        const p = Math.max(0, Math.min(100, c.pos == null ? (right ? 90 : 10) : c.pos));
        const v = Math.max(0, Math.min(100, c.vert == null ? 10 : c.vert));
        const leftPx = -90 + (p / 100) * (344 - W + 180); // balaye tout l'écran
        const bottomPx = -40 + (v / 100) * 300;           // monte / descend la plante
        const base = { width: W + "px", height: "734px", bottom: bottomPx + "px", left: leftPx + "px" };
        if (!right) base.transform = "scaleX(-1)";
        return (
          <div className="plant" key={i} style={base}>
            <Climber
              color={c.color}
              opacity={right ? .34 : .3}
              paleTop={PALE_BY[c.color] || "var(--c-primary-2)"}
              type={c.type}
            />
          </div>
        );
      })}

      {tufts.map((t, i) => (
        <div className="plant" key={"t" + i} style={t.pos}>
          <HerbTuft color={t.color} opacity={t.opacity} needles={t.needles} sprigs={t.sprigs} />
        </div>
      ))}
    </div>
  );
}

// ── phone ────────────────────────────────────────────────────────────────
function PhoneAromates({ scene = {} }) {
  return (
    <div className="phone" data-variant="t2" data-screen-label="Accueil · Aromates & grimpante">
      <SceneAromates {...scene} />
      <div className="pstatus"><span>8:24</span><Dots /></div>
      <div className="pbar">
        <div><div className="greet">Mardi 6 juin · Bonjour Camille</div><h1>Aujourd'hui</h1></div>
        <div className="acts"><button className="ibtn"><i className="ph ph-bell"></i><span className="bdg"></span></button><button className="ibtn"><i className="ph ph-dots-three-vertical"></i></button></div>
      </div>
      <div className="pscreen">
        <Weather />
        <div className="block">
          <p className="slabel">Tâches du jour <span className="count">3</span></p>
          <Tasks />
        </div>
        <div className="alert"><i className="ph-fill ph-bug-beetle"></i><span className="atx">Pucerons possibles sur les rosiers — surveille le dessous des feuilles.</span></div>
        <div className="block">
          <p className="slabel">Aperçu du potager <span className="count">3 zones</span></p>
          <div className="garden">
            <div className="gtile"><div className="pic veg-1"></div><div className="cap">Carré nord</div></div>
            <div className="gtile"><div className="pic veg-2"></div><div className="cap">Bac aromates</div></div>
            <div className="gtile"><div className="pic veg-3"></div><div className="cap">Serre</div></div>
          </div>
        </div>
      </div>
      <Nav />
    </div>
  );
}

Object.assign(window, { PhoneAromates, SceneAromates, Climber, Vine, HerbTuft, HerbSprig });
