/* accueil-final.jsx — Accueil DÉFINITIF · direction B « Tableau modulaire »
   Choisie comme écran d'accueil. Décor validé (phone t2) + divulgation
   progressive pilotée par le niveau d'expérience :
     Découverte → cœur seul (météo · tâches · alerte · potager)
     Apprenti   → + (déjà tout le potager)
     Jardinier  → + statistiques de saison (récoltes)
   Décor importé depuis aromates-grimpantes.jsx (window.SceneAromates).
   Export : PhoneAccueil */

function AcDots() {
  return (
    <span className="dots">
      <i className="ph-fill ph-cell-signal-full"></i>
      <i className="ph-fill ph-wifi-high"></i>
      <i className="ph-fill ph-battery-high"></i>
    </span>
  );
}

function AcNav() {
  const items = [
    ["house", "Accueil", true],
    ["plant", "Potager", false],
    ["book-open", "Catalogue", false],
    ["calendar-blank", "Calendrier", false],
    ["dots-three", "Plus", false],
  ];
  return (
    <div className="bnav">
      {items.map(([i, l, on]) => (
        <div className={"nav" + (on ? " active" : "")} key={l}>
          <i className={"ph" + (on ? "-fill" : "") + " ph-" + i}></i>
          <span>{l}</span>
        </div>
      ))}
    </div>
  );
}

function AcWeather() {
  return (
    <div className="weather">
      <i className="ph-duotone ph-cloud-sun"></i>
      <div>
        <div className="temp">18°</div>
        <div className="sub">Partiellement nuageux</div>
      </div>
      <span className="spacer"></span>
      <div className="ok"><b>Bon pour arroser</b><span>Pluie demain matin</span></div>
    </div>
  );
}

function AcGarden() {
  const zones = [["Carré nord", "veg-1"], ["Bac aromates", "veg-2"], ["Serre", "veg-3"]];
  return (
    <div className="garden">
      {zones.map(([cap, v]) => (
        <div className="gtile" key={cap}>
          <div className={"pic " + v}></div>
          <div className="cap">{cap}</div>
        </div>
      ))}
    </div>
  );
}

const AC_LEVELS = ["Découverte", "Apprenti", "Jardinier", "Expert"];

function PhoneAccueil({ scene, niveau = "Jardinier" }) {
  const idx = Math.max(0, AC_LEVELS.indexOf(niveau));
  const pct = [22, 52, 78, 100][idx];
  const statsUnlocked = idx >= 2; // « Jardinier » et +

  return (
    <div className="phone" data-variant="t2" data-screen-label="Accueil · Tableau modulaire">
      <SceneAromates {...scene} />
      <div className="pstatus"><span>8:24</span><AcDots /></div>

      <div className="pbar">
        <div>
          <div className="greet">Mardi 6 juin</div>
          <h1>Mon potager</h1>
        </div>
        <div className="acts">
          <button className="ibtn" aria-label="Notifications"><i className="ph ph-bell"></i><span className="bdg"></span></button>
          <button className="ibtn" aria-label="Plus d'options"><i className="ph ph-dots-three-vertical"></i></button>
        </div>
      </div>

      <div className="pscreen">
        <div className="levelrow">
          <span className="levelpill">
            <i className="ph-fill ph-seal-check"></i>{niveau}
            <span className="prog"><span style={{ width: pct + "%" }}></span></span>
          </span>
          <span className="zones"><i className="ph-fill ph-squares-four"></i>3 zones</span>
        </div>

        <AcWeather />

        <div className="block">
          <p className="slabel">Tâches du jour <span className="count">3</span></p>
          <div className="card">
            <div className="task">
              <span className="check"></span>
              <span className="tx"><span className="lab">Arroser les tomates</span></span>
              <span className="tag sage">Carré nord</span>
            </div>
            <div className="task done">
              <span className="check"></span>
              <span className="tx"><span className="lab">Récolter les aubergines</span></span>
              <span className="tag harvest">Fait</span>
            </div>
            <div className="seeall"><span>Voir les 3 tâches</span><i className="ph ph-caret-right"></i></div>
          </div>
        </div>

        <div className="statgrid">
          <div className="stat warn">
            <div className="row"><i className="ph-fill ph-warning-circle"></i><span className="big">1</span></div>
            <span className="lbl"><b style={{ color: "var(--c-ink)" }}>Alerte</b> · risque pucerons</span>
          </div>
          {statsUnlocked ? (
            <div className="stat harvest">
              <div className="row"><i className="ph-duotone ph-basket"></i><span className="big">12</span></div>
              <span className="lbl"><b style={{ color: "var(--c-ink)" }}>Récoltes</b> cette saison</span>
            </div>
          ) : (
            <div className="stat lock">
              <div className="row"><i className="ph-duotone ph-lock-simple"></i><span className="big">Saison</span></div>
              <span className="lbl">Stats au niveau Jardinier</span>
            </div>
          )}
        </div>

        <div className="block">
          <p className="slabel">Aperçu du potager</p>
          <AcGarden />
        </div>
      </div>

      <AcNav />
    </div>
  );
}

Object.assign(window, { PhoneAccueil });
