/* parametres.jsx — Panneau « Plus » + écran Paramètres (Carnet vivant)
   Un seul téléphone interactif :
   · base = Accueil (décor aromates importé de aromates-grimpantes.jsx)
   · onglet Plus → popover (ou bottom-sheet, cf. tweak openStyle)
   · Plus → Paramètres → 6 catégories (doc 11) → sous-panneaux fonctionnels
   Dépend de window.SceneAromates. Export : PlusApp */

const { useState, useEffect, useRef } = React;

/* ── briques chrome ── */
function Dots() {
  return <span className="dots"><i className="ph-fill ph-cell-signal-full"></i><i className="ph-fill ph-wifi-high"></i><i className="ph-fill ph-battery-high"></i></span>;
}

/* ── contrôles ── */
function Toggle({ on, onChange, disabled }) {
  return <button type="button" className={"tog" + (on ? " on" : "")} disabled={disabled}
    role="switch" aria-checked={on} onClick={() => !disabled && onChange(!on)} />;
}
function Segmented({ value, options, onChange }) {
  return (
    <div className="seg" role="tablist">
      {options.map(([val, lab]) => (
        <button key={val} type="button" role="tab" aria-selected={value === val}
          className={value === val ? "on" : ""} onClick={() => onChange(val)}>{lab}</button>
      ))}
    </div>
  );
}
/* rangée switch inline */
function SwitchRow({ icon, tint, label, sub, on, onChange, disabled }) {
  return (
    <div className={"srow" + (disabled ? " dim" : "")}>
      {icon && <span className={"si " + tint}><i className={icon}></i></span>}
      <span className="stx"><span className="sl">{label}</span>{sub && <span className="ss">{sub}</span>}</span>
      <span className="sctl"><Toggle on={on} onChange={onChange} disabled={disabled} /></span>
    </div>
  );
}
/* champ empilé (label + contrôle pleine largeur) */
function FieldStack({ icon, label, hint, children }) {
  return (
    <div className="fstack">
      <div className="fhead">
        <span className="flabel">{icon && <i className={icon}></i>}{label}</span>
        {hint && <span className="fhint">{hint}</span>}
      </div>
      {children}
    </div>
  );
}

/* ════════════════════════════════════════════════════════════
   BASE — Accueil (contexte derrière le menu Plus)
   ════════════════════════════════════════════════════════════ */
function AccueilBase({ scene, onPlus, plusOpen }) {
  const items = [
    ["house", "Accueil", false],
    ["plant", "Potager", false],
    ["book-open", "Catalogue", false],
    ["calendar-blank", "Calendrier", false],
  ];
  return (
    <>
      <SceneAromates {...scene} />
      <div className="pstatus"><span>8:24</span><Dots /></div>
      <div className="pbar">
        <div><div className="greet">Lundi 9 juin · Bonjour Camille</div><h1>Aujourd'hui</h1></div>
        <div className="acts">
          <button className="ibtn" aria-label="Notifications"><i className="ph ph-bell"></i><span className="bdg"></span></button>
          <button className="ibtn" aria-label="Plus d'options"><i className="ph ph-dots-three-vertical"></i></button>
        </div>
      </div>
      <div className="pscreen">
        <div className="weather">
          <i className="ph-duotone ph-cloud-sun"></i>
          <div><div className="temp">18°</div><div className="sub">Partiellement nuageux</div></div>
          <span className="spacer"></span>
          <div className="ok"><b>Bon pour arroser</b><span>Pluie demain</span></div>
        </div>
        <div className="block">
          <p className="slabel">Tâches du jour <span className="count">3</span></p>
          <div className="card">
            <div className="task"><span className="check"></span><span className="tx"><span className="lab">Arroser les tomates</span></span><span className="tag sage">Carré nord</span></div>
            <div className="task"><span className="check"></span><span className="tx"><span className="lab">Semer les radis</span></span><span className="tag warm">Bac aromates</span></div>
            <div className="task"><span className="check"></span><span className="tx"><span className="lab">Récolter les aubergines</span></span><span className="tag harvest">À maturité</span></div>
          </div>
        </div>
        <div className="block">
          <p className="slabel">Aperçu du potager <span className="count">3 zones</span></p>
          <div className="garden">
            <div className="gtile"><div className="pic veg-1"></div><div className="cap">Carré nord</div></div>
            <div className="gtile"><div className="pic veg-2"></div><div className="cap">Bac aromates</div></div>
            <div className="gtile"><div className="pic veg-3"></div><div className="cap">Serre</div></div>
          </div>
        </div>
      </div>
      <div className="bnav">
        {items.map(([i, l]) => (
          <button className="nav" key={l} type="button"><i className={"ph ph-" + i}></i><span>{l}</span></button>
        ))}
        <button type="button" className={"nav" + (plusOpen ? " open" : "")} onClick={onPlus} aria-haspopup="menu" aria-expanded={plusOpen}>
          <i className={"ph" + (plusOpen ? "-fill" : "") + " ph-dots-three"}></i><span>Plus</span>
        </button>
      </div>
    </>
  );
}

/* ════════════════════════════════════════════════════════════
   MENU « PLUS » — entrées (doc 09 + réponse user)
   ════════════════════════════════════════════════════════════ */
const PLUS_ITEMS = [
  { id: "parametres", icon: "ph ph-sliders-horizontal", tint: "tint-prim", label: "Paramètres", sub: "Préférences, données, à propos" },
  { id: "postrecolte", icon: "ph ph-package", tint: "tint-aub", label: "Post-récolte", sub: "Conservation & transformation" },
  { id: "communaute", icon: "ph ph-users-three", tint: "tint-deep", label: "Communauté", sub: "Partage entre jardiniers", v2: true },
  { id: "apropos", icon: "ph ph-info", tint: "tint-terre", label: "À propos", sub: "Version, licence, transparence" },
];

function PlusPopover({ onPick, onClose }) {
  return (
    <>
      <div className="pop-scrim" onClick={onClose}></div>
      <div className="plus-pop" role="menu" aria-label="Plus">
        <div className="pop-head"><i className="ph-fill ph-dots-three"></i><span>PLUS</span></div>
        <div className="pop-sep"></div>
        {PLUS_ITEMS.map((it) => (
          <button key={it.id} type="button" role="menuitem"
            className={"pop-row" + (it.v2 ? " disabled" : "")}
            onClick={() => !it.v2 && onPick(it.id)} disabled={it.v2}>
            <span className={"pi " + it.tint}><i className={it.icon}></i></span>
            <span className="pl"><b>{it.label}</b><span>{it.sub}</span></span>
            {it.v2 ? <span className="v2">V2</span> : <i className="ph ph-caret-right chev"></i>}
          </button>
        ))}
      </div>
    </>
  );
}

function PlusSheet({ onPick, onClose }) {
  return (
    <>
      <div className="sheet-scrim" onClick={onClose}></div>
      <div className="sheet" role="menu" aria-label="Plus">
        <div className="grip"></div>
        <div className="sheet-h"><i className="ph-fill ph-dots-three"></i><b>Plus</b>
          <button type="button" className="x" onClick={onClose} aria-label="Fermer"><i className="ph ph-x"></i></button></div>
        {PLUS_ITEMS.map((it) => (
          <button key={it.id} type="button" role="menuitem"
            className={"pop-row" + (it.v2 ? " disabled" : "")}
            onClick={() => !it.v2 && onPick(it.id)} disabled={it.v2}>
            <span className={"pi " + it.tint}><i className={it.icon}></i></span>
            <span className="pl"><b>{it.label}</b><span>{it.sub}</span></span>
            {it.v2 ? <span className="v2">V2</span> : <i className="ph ph-caret-right chev"></i>}
          </button>
        ))}
      </div>
    </>
  );
}

/* ════════════════════════════════════════════════════════════
   ÉCRAN PARAMÈTRES — racine (6 catégories doc 11)
   ════════════════════════════════════════════════════════════ */
const CATEGORIES = [
  { id: "general", icon: "ph ph-sliders-horizontal", tint: "tint-prim", label: "Préférences générales", sub: "Langue, thème, unités, gestes, niveau" },
  { id: "confid", icon: "ph ph-shield-check", tint: "tint-aub", label: "Confidentialité & opt-outs", sub: "Géoloc, sync, météo, communauté" },
  { id: "notif", icon: "ph ph-bell", tint: "tint-ocre", label: "Notifications", sub: "Maître, catégories, ne pas déranger" },
  { id: "sync", icon: "ph ph-arrows-clockwise", tint: "tint-info", label: "Synchronisation & sauvegarde", sub: "Appareils, export, import" },
  { id: "transp", icon: "ph ph-database", tint: "tint-deep", label: "Transparence des données", sub: "Données stockées, journal, politique" },
  { id: "apropos", icon: "ph ph-info", tint: "tint-terre", label: "À propos", sub: "Version, licence, crédits" },
];
const LEVEL_LABEL = { debutant: "Débutant", intermediaire: "Intermédiaire", expert: "Expert" };

function ParametresRoot({ prefs, onOpen, onBack }) {
  return (
    <div className="scr">
      <div className="scr-bar">
        <button type="button" className="scr-back" onClick={onBack} aria-label="Fermer"><i className="ph ph-x"></i></button>
        <h2>Paramètres</h2>
      </div>
      <div className="scr-body">
        <div className="profile">
          <span className="pav"><i className="ph-fill ph-leaf"></i></span>
          <div className="pinfo">
            <b>Mon carnet</b>
            <span><i className="ph-fill ph-seal-check"></i>Niveau {LEVEL_LABEL[prefs.niveau]} · 100 % local</span>
          </div>
        </div>
        <div className="cat-group">
          {CATEGORIES.map((c) => (
            <button key={c.id} type="button" className="catrow" onClick={() => onOpen(c.id)}>
              <span className={"ci " + c.tint}><i className={c.icon}></i></span>
              <span className="ct"><span className="cl">{c.label}</span><span className="cs">{c.sub}</span></span>
              <i className="ph ph-caret-right chev"></i>
            </button>
          ))}
        </div>
        <div className="zone-foot">
          <i className="ph-fill ph-lock-simple"></i>
          <span>Toutes les préférences sont stockées localement sur cet appareil et ne sont jamais synchronisées sans ton accord.</span>
        </div>
      </div>
    </div>
  );
}

/* ════════════════════════════════════════════════════════════
   SOUS-PANNEAUX
   ════════════════════════════════════════════════════════════ */
function SubPanel({ title, onBack, children }) {
  return (
    <div className="scr sub">
      <div className="scr-bar">
        <button type="button" className="scr-back" onClick={onBack} aria-label="Retour"><i className="ph-bold ph-caret-left"></i></button>
        <h2>{title}</h2>
      </div>
      <div className="scr-body">{children}</div>
    </div>
  );
}

/* — Catégorie 1 : Préférences générales — */
function GeneralPanel({ prefs, set, onBack }) {
  return (
    <SubPanel title="Préférences générales" onBack={onBack}>
      <div className="zone">
        <div className="sgroup">
          <FieldStack icon="ph ph-translate" label="Langue">
            <Segmented value={prefs.langue} onChange={(v) => set("langue", v)}
              options={[["auto", "Auto"], ["fr", "Français"], ["en", "English"]]} />
          </FieldStack>
          <FieldStack icon="ph ph-paint-roller" label="Thème" hint="Aperçu visuel">
            <Segmented value={prefs.theme} onChange={(v) => set("theme", v)}
              options={[["auto", "Auto"], ["clair", "Clair"], ["sombre", "Sombre"]]} />
          </FieldStack>
          <FieldStack icon="ph ph-ruler" label="Système d'unités">
            <Segmented value={prefs.unites} onChange={(v) => set("unites", v)}
              options={[["metrique", "Métrique"], ["imperial", "Impérial"]]} />
          </FieldStack>
        </div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-hand-swipe-right"></i>Sens des gestes</div>
        <div className="sgroup">
          <FieldStack label="Balayage des listes">
            <Segmented value={prefs.swipe} onChange={(v) => set("swipe", v)}
              options={[["standard", "Standard"], ["inverse", "Inversé"]]} />
            <div className="swipe-demo">
              <span className="chip done"><i className="ph-bold ph-check"></i>Faite</span>
              <span className="demo-card">
                <i className={prefs.swipe === "standard" ? "ph ph-arrow-right" : "ph ph-arrow-left"}></i>
                glisse une tâche
                <i className={prefs.swipe === "standard" ? "ph ph-arrow-left" : "ph ph-arrow-right"}></i>
              </span>
              <span className="chip snooze"><i className="ph-bold ph-clock-clockwise"></i>Reporter</span>
            </div>
          </FieldStack>
        </div>
        <div className="zone-foot"><i className="ph ph-info"></i><span>Ce réglage s'applique partout où une liste se balaie (tâches, plantations…).</span></div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-seal-check"></i>Niveau d'expérience</div>
        <div className="sgroup">
          <FieldStack label="Détail des recommandations" hint="Options avancées">
            <Segmented value={prefs.niveau} onChange={(v) => set("niveau", v)}
              options={[["debutant", "Débutant"], ["intermediaire", "Intermédiaire"], ["expert", "Expert"]]} />
          </FieldStack>
        </div>
        <div className="zone-foot"><i className="ph ph-plant"></i><span>Un niveau plus élevé affiche des conseils plus pointus et déverrouille les options avancées.</span></div>
      </div>
    </SubPanel>
  );
}

/* — Catégorie 2 : Confidentialité & opt-outs — */
const GEO_LABEL = { off: "Désactivée", manuelle: "Manuelle (ville)", gps: "GPS" };
function ConfidentialitePanel({ prefs, set, onBack }) {
  const geoCycle = () => {
    const order = ["off", "manuelle", "gps"];
    set("geo", order[(order.indexOf(prefs.geo) + 1) % order.length]);
  };
  return (
    <SubPanel title="Confidentialité & opt-outs" onBack={onBack}>
      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-shield-check"></i>Vos données vous appartiennent</div>
        <div className="sgroup">
          <div className="srow tap" onClick={geoCycle}>
            <span className="si tint-info"><i className="ph ph-map-pin"></i></span>
            <span className="stx"><span className="sl">Géolocalisation</span>
              <span className="ss">{prefs.geo === "off" ? "Désactivée — météo & zone climatique saisies à la main" : prefs.geo === "manuelle" ? "Ville saisie manuellement" : "Position GPS de l'appareil"}</span></span>
            <span className="sctl"><span className="val">{GEO_LABEL[prefs.geo]}</span><i className="ph ph-caret-right chev"></i></span>
          </div>
          <SwitchRow icon="ph ph-cloud-sun" tint="tint-info" label="Récupération météo auto"
            sub={prefs.meteoAuto ? "Actualisation automatique" : "Carte météo masquée — actualisation manuelle"}
            on={prefs.meteoAuto} onChange={(v) => set("meteoAuto", v)} />
          <SwitchRow icon="ph ph-wifi-high" tint="tint-prim" label="Synchronisation WiFi locale"
            sub="Entre vos appareils, sur le réseau local" on={prefs.sync} onChange={(v) => set("sync", v)} />
          <SwitchRow icon="ph ph-moon-stars" tint="tint-aub" label="Calendrier lunaire"
            sub="Repères lunaires pour les semis" on={prefs.lunaire} onChange={(v) => set("lunaire", v)} />
          <SwitchRow icon="ph ph-users-three" tint="tint-deep" label="Communauté P2P"
            sub="Partage pair-à-pair — disponible en V2" on={false} onChange={() => {}} disabled />
        </div>
        <div className="zone-foot"><i className="ph-fill ph-leaf"></i>
          <span><b style={{ color: "var(--c-ink)" }}>Règle d'or :</b> aucune fonctionnalité n'est cassée par une désactivation — un mode de repli est toujours prévu.</span></div>
      </div>
    </SubPanel>
  );
}

/* — Catégorie 3 : Notifications — */
const NOTIF_CATS = [
  ["semis", "ph ph-seedling", "Semis", "Fenêtres & rappels de semis"],
  ["arrosage", "ph ph-drop", "Arrosage", "Selon météo & besoins"],
  ["recolte", "ph ph-basket", "Récolte", "Quand c'est à maturité"],
  ["meteo", "ph ph-cloud-lightning", "Météo critique", "Gel, canicule, orage"],
  ["entretien", "ph ph-scissors", "Entretien", "Taille, tuteurage, désherbage"],
  ["rotation", "ph ph-arrows-clockwise", "Rotation", "Conseils de rotation des cultures"],
];
function NotificationsPanel({ prefs, set, setNotif, onBack }) {
  const master = prefs.notifMaster;
  return (
    <SubPanel title="Notifications" onBack={onBack}>
      <div className="zone">
        <div className="sgroup">
          <SwitchRow icon="ph-fill ph-bell-ringing" tint="tint-ocre" label="Toutes les notifications"
            sub={master ? "Activées" : "Coupées — rappels visibles dans l'app uniquement"}
            on={master} onChange={(v) => set("notifMaster", v)} />
        </div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-squares-four"></i>Par catégorie</div>
        <div className="sgroup">
          {NOTIF_CATS.map(([key, icon, label, sub]) => (
            <SwitchRow key={key} icon={icon} tint="tint-prim" label={label} sub={sub}
              on={master && prefs.notif[key]} disabled={!master}
              onChange={(v) => setNotif(key, v)} />
          ))}
        </div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-moon"></i>Ne pas déranger</div>
        <div className="sgroup">
          <SwitchRow icon="ph ph-bell-slash" tint="tint-aub" label="Créneau silencieux"
            sub="Aucune notification sur la plage choisie" on={prefs.dnd} disabled={!master}
            onChange={(v) => set("dnd", v)} />
          {master && prefs.dnd && (
            <div className="fstack">
              <div className="timepair">
                <div className="tbox"><div className="tk">Début</div><div className="tv">22:00</div></div>
                <span className="tdash"><i className="ph-bold ph-arrow-right"></i></span>
                <div className="tbox"><div className="tk">Fin</div><div className="tv">07:00</div></div>
              </div>
            </div>
          )}
        </div>
      </div>
    </SubPanel>
  );
}

/* — Catégorie 4 : Synchronisation & sauvegarde — */
function SyncPanel({ prefs, set, onExport, onReset, onBack }) {
  return (
    <SubPanel title="Synchronisation & sauvegarde" onBack={onBack}>
      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-wifi-high"></i>Synchronisation locale</div>
        <div className={"syncstat" + (prefs.sync ? " active" : "")}>
          <span className="sdot"></span>
          <div className="si2"><b>{prefs.sync ? "Activée" : "Désactivée"}</b>
            <span>{prefs.sync ? "Dernière sync il y a 2 h · 1 appareil appairé" : "Aucun appareil appairé"}</span></div>
          <Toggle on={prefs.sync} onChange={(v) => set("sync", v)} />
        </div>
        {prefs.sync && (
          <div className="sgroup" style={{ marginTop: "12px" }}>
            <div className="srow">
              <span className="si tint-prim"><i className="ph ph-device-mobile"></i></span>
              <span className="stx"><span className="sl">Tablette cuisine</span><span className="ss">Appairée · à l'instant</span></span>
            </div>
            <button type="button" className="actrow"><span className="ai tint-prim"><i className="ph ph-plus"></i></span>
              <span className="at"><span className="al">Appairer un appareil</span><span className="as">Sur le même réseau WiFi</span></span>
              <i className="ph ph-caret-right chev"></i></button>
          </div>
        )}
        <div className="zone-foot"><i className="ph ph-info"></i><span>La synchronisation reste sur ton réseau local — rien ne transite par un serveur externe.</span></div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-export"></i>Export & import</div>
        <div className="sgroup">
          <button type="button" className="actrow" onClick={() => onExport("JSON")}>
            <span className="ai tint-info"><i className="ph ph-file-js"></i></span>
            <span className="at"><span className="al">Exporter en JSON</span><span className="as">Sauvegarde intégrale</span></span>
            <i className="ph ph-download-simple chev"></i></button>
          <button type="button" className="actrow" onClick={() => onExport("CSV")}>
            <span className="ai tint-info"><i className="ph ph-file-csv"></i></span>
            <span className="at"><span className="al">Exporter en CSV</span><span className="as">Une feuille par table</span></span>
            <i className="ph ph-download-simple chev"></i></button>
          <button type="button" className="actrow">
            <span className="ai tint-prim"><i className="ph ph-upload-simple"></i></span>
            <span className="at"><span className="al">Importer une sauvegarde</span><span className="as">Restaurer depuis un export</span></span>
            <i className="ph ph-caret-right chev"></i></button>
        </div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-warning"></i>Zone sensible</div>
        <div className="sgroup">
          <button type="button" className="actrow danger" onClick={onReset}>
            <span className="ai"><i className="ph ph-trash"></i></span>
            <span className="at"><span className="al">Réinitialiser toutes les données</span><span className="as">Suppression locale · double confirmation</span></span>
            <i className="ph ph-caret-right chev"></i></button>
        </div>
      </div>
    </SubPanel>
  );
}

/* — Catégorie 5 : Transparence des données — */
const DATA_TABLES = [
  ["Potagers & zones", "14 enr.", "82 Ko"],
  ["Plantations", "37 enr.", "0,4 Mo"],
  ["Tâches & rappels", "126 enr.", "0,3 Mo"],
  ["Récoltes", "58 enr.", "0,2 Mo"],
  ["Photos & observations", "23 enr.", "6,1 Mo"],
  ["Fiches & catalogue perso", "9 enr.", "0,1 Mo"],
];
function TransparencePanel({ onBack }) {
  return (
    <SubPanel title="Transparence des données" onBack={onBack}>
      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-database"></i>Données stockées sur l'appareil</div>
        <div className="sgroup">
          <div className="dtable">
            {DATA_TABLES.map(([n, c, z]) => (
              <div className="dt-row" key={n}><span className="dn">{n}</span><span className="dc">{c}</span><span className="dz">{z}</span></div>
            ))}
            <div className="dt-foot"><span className="dn">Total</span><span className="dz">7,2 Mo</span></div>
          </div>
        </div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-list-magnifying-glass"></i>Journal des accès sensibles</div>
        <div className="sgroup">
          <div className="srow"><span className="si tint-info"><i className="ph ph-map-pin"></i></span>
            <span className="stx"><span className="sl">Géolocalisation</span><span className="ss">Jamais accédée · désactivée</span></span></div>
          <div className="srow"><span className="si tint-ocre"><i className="ph ph-bell"></i></span>
            <span className="stx"><span className="sl">Notifications</span><span className="ss">Dernier accès aujourd'hui, 8:00</span></span></div>
        </div>
      </div>

      <div className="zone">
        <div className="sgroup">
          <button type="button" className="actrow">
            <span className="ai tint-aub"><i className="ph ph-file-text"></i></span>
            <span className="at"><span className="al">Politique de confidentialité</span><span className="as">Texte clair · consultable hors-ligne</span></span>
            <i className="ph ph-caret-right chev"></i></button>
        </div>
        <div className="zone-foot"><i className="ph-fill ph-lock-simple"></i><span>Aucune donnée ne quitte l'appareil. Pas de compte, pas de traceur, pas de serveur.</span></div>
      </div>
    </SubPanel>
  );
}

/* — Catégorie 6 : À propos — */
function AProposPanel({ onOpen, onBack }) {
  return (
    <SubPanel title="À propos" onBack={onBack}>
      <div className="aboutid">
        <span className="mark"><i className="ph-fill ph-leaf"></i></span>
        <h3>Carnet vivant</h3>
        <span className="ver">Version 1.0.0 · build 1042</span>
        <span className="lic"><i className="ph-fill ph-seal-check"></i>Licence MIT · open source</span>
      </div>
      <div className="botany"><i className="ph-fill ph-leaf"></i></div>

      <div className="zone">
        <div className="sgroup">
          <a className="actrow" href="#" onClick={(e) => e.preventDefault()}>
            <span className="ai tint-deep"><i className="ph ph-github-logo"></i></span>
            <span className="at"><span className="al">Code source</span><span className="as">github.com/carnet-vivant</span></span>
            <i className="ph ph-arrow-up-right chev"></i></a>
          <button type="button" className="actrow">
            <span className="ai tint-prim"><i className="ph ph-book-open-text"></i></span>
            <span className="at"><span className="al">Documentation</span></span>
            <i className="ph ph-arrow-up-right chev"></i></button>
          <button type="button" className="actrow">
            <span className="ai tint-ocre"><i className="ph ph-bug"></i></span>
            <span className="at"><span className="al">Signaler un bug</span></span>
            <i className="ph ph-arrow-up-right chev"></i></button>
          <button type="button" className="actrow">
            <span className="ai tint-aub"><i className="ph ph-hand-heart"></i></span>
            <span className="at"><span className="al">Contribuer</span></span>
            <i className="ph ph-arrow-up-right chev"></i></button>
        </div>
      </div>

      <div className="zone">
        <div className="zone-h"><i className="ph-fill ph-users"></i>Crédits</div>
        <div className="sgroup">
          <div className="srow"><span className="stx"><span className="sl">Contributeurs</span><span className="ss">Communauté open source</span></span></div>
          <div className="srow"><span className="stx"><span className="sl">Données plantes</span><span className="ss">Bases ouvertes & domaine public</span></span></div>
          <div className="srow"><span className="stx"><span className="sl">Icônes</span><span className="ss">Phosphor Icons (MIT)</span></span></div>
        </div>
      </div>

      <div className="zone">
        <div className="sgroup">
          <button type="button" className="actrow" onClick={() => onOpen("transp")}>
            <span className="ai tint-deep"><i className="ph ph-database"></i></span>
            <span className="at"><span className="al">Transparence des données</span><span className="as">Ce qui est stocké & le journal des accès</span></span>
            <i className="ph ph-caret-right chev"></i></button>
        </div>
      </div>
    </SubPanel>
  );
}

/* ════════════════════════════════════════════════════════════
   APP
   ════════════════════════════════════════════════════════════ */
const DEFAULT_PREFS = {
  langue: "auto", theme: "auto", unites: "metrique", swipe: "standard", niveau: "debutant",
  geo: "off", meteoAuto: true, sync: false, lunaire: false,
  notifMaster: true, dnd: false,
  notif: { semis: true, arrosage: true, recolte: true, meteo: true, entretien: false, rotation: false },
};

function PlusApp({ scene, openStyle = "popover" }) {
  const [plusOpen, setPlusOpen] = useState(false);
  const [stack, setStack] = useState([]);          // ex: ["parametres", "general"]
  const [prefs, setPrefs] = useState(DEFAULT_PREFS);
  const [dialog, setDialog] = useState(null);       // { step }
  const [snack, setSnack] = useState(null);

  const set = (k, v) => setPrefs((p) => ({ ...p, [k]: v }));
  const setNotif = (k, v) => setPrefs((p) => ({ ...p, notif: { ...p.notif, [k]: v } }));

  const snackTimer = useRef(null);
  const flash = (txt) => {
    setSnack({ txt });
    clearTimeout(snackTimer.current);
    snackTimer.current = setTimeout(() => setSnack(null), 2600);
  };
  useEffect(() => () => clearTimeout(snackTimer.current), []);

  const pickPlus = (id) => {
    setPlusOpen(false);
    if (id === "parametres") setStack(["parametres"]);
    else if (id === "apropos") setStack(["parametres", "apropos"]);
    else flash("Section « " + id + " » — à venir");
  };
  const openSub = (id) => setStack((s) => [...s, id]);
  const back = () => setStack((s) => s.slice(0, -1));
  const closeAll = () => setStack([]);

  const top = stack[stack.length - 1];

  return (
    <div className="phone" data-variant="t2" data-screen-label="Plus & Paramètres">
      <AccueilBase scene={scene} plusOpen={plusOpen} onPlus={() => setPlusOpen((o) => !o)} />

      {plusOpen && (openStyle === "sheet"
        ? <PlusSheet onPick={pickPlus} onClose={() => setPlusOpen(false)} />
        : <PlusPopover onPick={pickPlus} onClose={() => setPlusOpen(false)} />)}

      {stack[0] === "parametres" && (
        <>
          <ParametresRoot prefs={prefs} onOpen={openSub} onBack={closeAll} />
          {top === "general" && <GeneralPanel prefs={prefs} set={set} onBack={back} />}
          {top === "confid" && <ConfidentialitePanel prefs={prefs} set={set} onBack={back} />}
          {top === "notif" && <NotificationsPanel prefs={prefs} set={set} setNotif={setNotif} onBack={back} />}
          {top === "sync" && <SyncPanel prefs={prefs} set={set} onBack={back}
            onExport={(fmt) => flash("Export " + fmt + " généré")} onReset={() => setDialog({ step: 1 })} />}
          {top === "transp" && <TransparencePanel onBack={back} />}
          {top === "apropos" && <AProposPanel onOpen={openSub} onBack={back} />}
        </>
      )}

      {dialog && (
        <div className="dlg-scrim" onClick={() => setDialog(null)}>
          <div className="dlg" onClick={(e) => e.stopPropagation()}>
            <span className="dlg-ic"><i className="ph-fill ph-warning"></i></span>
            <h4>{dialog.step === 1 ? "Tout réinitialiser ?" : "Es-tu vraiment sûr·e ?"}</h4>
            <p>{dialog.step === 1
              ? "Toutes tes données locales (potagers, plantations, récoltes, photos) seront supprimées de cet appareil."
              : "Cette action est définitive. Pense à exporter une sauvegarde avant de continuer."}</p>
            <div className="dlg-btns">
              <button type="button" className="b-danger"
                onClick={() => dialog.step === 1 ? setDialog({ step: 2 }) : (setDialog(null), flash("Données réinitialisées"))}>
                {dialog.step === 1 ? "Continuer" : "Supprimer définitivement"}
              </button>
              <button type="button" className="b-ghost" onClick={() => setDialog(null)}>Annuler</button>
            </div>
          </div>
        </div>
      )}

      {snack && (
        <div className="snack">
          <i className="ph-fill ph-check-circle"></i>
          <span className="stxt">{snack.txt}</span>
          <button type="button" className="undo" onClick={() => setSnack(null)}>OK</button>
        </div>
      )}
    </div>
  );
}

Object.assign(window, { PlusApp });
