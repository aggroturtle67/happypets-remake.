import { useEffect, useRef, useState } from "react";
import {
  Armchair,
  ArrowDownToLine,
  ArrowRight,
  Bone,
  Check,
  CheckCheck,
  ChevronRight,
  CircleHelp,
  Coins,
  Gift,
  Heart,
  House,
  Leaf,
  ListChecks,
  LockKeyhole,
  PawPrint,
  Pencil,
  Plus,
  ShoppingBag,
  Sparkles,
  Star,
  Sun,
  Utensils,
  Warehouse,
  X,
} from "lucide-react";
import {
  adopt,
  advanceTime,
  buyDecor,
  care,
  claimGift,
  claimQuest,
  dateKey,
  DECOR,
  levelOf,
  MAX_PETS,
  moveFurniture,
  newGame,
  parseSave,
  PETS,
  QUESTS,
  renamePet,
  SPECIES_LABEL,
  STORAGE_KEY,
  type Action,
  type FurnitureKind,
  type Game,
  type Pet,
  type Result,
} from "./game";
import { FurnitureArt, PetArt } from "./components/Art";
import Dialog from "./components/Dialog";
import Room from "./components/Room";

type Modal = "shop" | "quests" | "help" | "rename" | "inventory" | null;
function loadInitial() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { game: newGame(), warning: "" };
    const parsed = parseSave(raw);
    if (parsed) return { game: advanceTime(parsed), warning: "" };
    localStorage.setItem(`${STORAGE_KEY}.backup`, raw);
    return {
      game: newGame(),
      warning:
        "Der alte Spielstand konnte nicht gelesen werden. Eine Sicherung wurde im Browser aufbewahrt.",
    };
  } catch {
    return {
      game: newGame(),
      warning:
        "Der Browserspeicher ist nicht verfügbar. Dein Fortschritt bleibt nur in dieser Sitzung erhalten.",
    };
  }
}

function NeedBar({
  label,
  value,
  color,
  icon,
}: {
  label: string;
  value: number;
  color: string;
  icon: React.ReactNode;
}) {
  return (
    <div className="need">
      <div className="need-label">
        <span>
          {icon}
          {label}
        </span>
        <span>
          {Math.round(value)}
          <small> / 100</small>
        </span>
      </div>
      <div
        className="need-track"
        role="progressbar"
        aria-label={label}
        aria-valuenow={Math.round(value)}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <span style={{ width: `${value}%`, background: color }} />
      </div>
    </div>
  );
}
function CoinPrice({ value }: { value: number }) {
  return (
    <span className="coin-price">
      <Coins size={15} />
      {value}
    </span>
  );
}

export default function App() {
  const [initial] = useState(loadInitial);
  const [game, setGame] = useState<Game>(initial.game);
  const [modal, setModal] = useState<Modal>(null);
  const [shopTab, setShopTab] = useState<"pets" | "decor">("pets");
  const [editing, setEditing] = useState(false);
  const [selectedFurniture, setSelectedFurniture] = useState<string | null>(
    null,
  );
  const [activity, setActivity] = useState<{
    id: string;
    text: string;
    key: number;
  } | null>(null);
  const [toast, setToast] = useState<{ text: string; success: boolean } | null>(
    null,
  );
  const [saved, setSaved] = useState(true);
  const [warning, setWarning] = useState(initial.warning);
  const [petName, setPetName] = useState("");
  const activityTimer = useRef<number | undefined>(undefined);
  const toastTimer = useRef<number | undefined>(undefined);
  const selectedPet = game.pets.find((p) => p.id === game.selectedPet)!;
  const level = levelOf(game.xp);
  const availableQuests = QUESTS.filter(
    (q) => game.quests.progress[q.id] && !game.quests.claimed.includes(q.id),
  ).length;

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(game));
      setSaved(true);
    } catch {
      setSaved(false);
    }
  }, [game]);
  useEffect(() => {
    const timer = window.setInterval(
      () => setGame((g) => advanceTime(g)),
      15_000,
    );
    const onVisible = () => {
      if (document.visibilityState === "visible")
        setGame((g) => advanceTime(g));
    };
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", onVisible);
      clearTimeout(activityTimer.current);
      clearTimeout(toastTimer.current);
    };
  }, []);

  function notify(text: string, success = true) {
    clearTimeout(toastTimer.current);
    setToast({ text, success });
    toastTimer.current = window.setTimeout(() => setToast(null), 4500);
  }
  function run(result: Result) {
    if (result.success) {
      if (levelOf(result.game.xp) > level)
        notify(
          `Juhu, Level ${levelOf(result.game.xp)}! Deine Pfotenstube wächst.`,
        );
      else notify(result.message);
      setGame(result.game);
    } else notify(result.message, false);
    return result.success;
  }
  function doCare(action: Action, id = game.selectedPet) {
    const result = care({ ...game, selectedPet: id }, id, action);
    if (run(result)) {
      const texts = {
        feed: "Mmmh! ♡",
        play: "Juhuu! ✦",
        clean: "Blitzblank! ✧",
        pet: "Hab dich lieb! ♡",
      };
      clearTimeout(activityTimer.current);
      setActivity({ id, text: texts[action], key: Date.now() });
      activityTimer.current = window.setTimeout(() => setActivity(null), 3500);
    }
  }
  function openShop(tab: "pets" | "decor" = "pets") {
    setShopTab(tab);
    setModal("shop");
  }
  function selectPet(id: string) {
    setGame((g) => ({ ...g, selectedPet: id }));
  }
  function newId() {
    return crypto.randomUUID();
  }
  function purchaseDecor(kind: FurnitureKind) {
    const id = newId();
    if (run(buyDecor(game, kind, id))) {
      setSelectedFurniture(id);
      setEditing(true);
      setModal(null);
    }
  }
  function furnitureAction(action: "flip" | "store") {
    setGame((g) => ({
      ...g,
      furniture: g.furniture.map((f) =>
        f.id === selectedFurniture
          ? {
              ...f,
              flipped: action === "flip" ? !f.flipped : f.flipped,
              placed: action === "store" ? false : f.placed,
            }
          : f,
      ),
    }));
    if (action === "store") {
      setSelectedFurniture(null);
      notify(
        "Im Möbellager verstaut. Du kannst es jederzeit wieder aufstellen.",
      );
    }
  }
  function restoreFurniture(id: string) {
    setGame((g) => ({
      ...g,
      furniture: g.furniture.map((f) =>
        f.id === id
          ? { ...f, placed: true, x: 50, y: f.kind === "rug" ? 88 : 74 }
          : f,
      ),
    }));
    setSelectedFurniture(id);
    setEditing(true);
    setModal(null);
  }
  function downloadSave() {
    const blob = new Blob([JSON.stringify(game, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "pfotenstube-spielstand.json";
    a.click();
    URL.revokeObjectURL(url);
    notify("Dein Spielstand wurde als Datei exportiert.");
  }
  async function importSave(file: File | undefined) {
    if (!file) return;
    if (file.size > 200_000) {
      notify("Diese Datei ist zu groß für einen Spielstand.", false);
      return;
    }
    try {
      const parsed = parseSave(await file.text());
      if (!parsed) {
        notify(
          "Diese Datei enthält keinen gültigen Pfotenstube-Spielstand.",
          false,
        );
        return;
      }
      if (
        !window.confirm("Aktuellen Spielstand durch diese Sicherung ersetzen?")
      )
        return;
      try {
        localStorage.setItem(`${STORAGE_KEY}.backup`, JSON.stringify(game));
      } catch {
        /* Session can still be restored without storage. */
      }
      setGame(advanceTime(parsed));
      setEditing(false);
      setSelectedFurniture(null);
      setModal(null);
      notify("Deine Pfoten sind wieder zu Hause. Spielstand importiert!");
    } catch {
      notify("Die Datei konnte nicht gelesen werden.", false);
    }
  }

  return (
    <div className="app-shell">
      <aside className="nav-rail" aria-label="Hauptnavigation">
        <a
          className="rail-brand"
          href="#"
          aria-label="Pfotenstube Startseite"
          onClick={(e) => {
            e.preventDefault();
            setModal(null);
          }}
        >
          <PawPrint size={29} fill="currentColor" />
        </a>
        <div className="rail-links">
          <button
            className={!modal || modal === "rename" ? "active" : ""}
            onClick={() => setModal(null)}
            aria-label="Zuhause"
            title="Zuhause"
          >
            <House size={22} />
            <span>Zuhause</span>
          </button>
          <button
            className={modal === "shop" ? "active" : ""}
            onClick={() => openShop()}
            aria-label="Laden"
            title="Laden"
          >
            <ShoppingBag size={22} />
            <span>Laden</span>
          </button>
          <button
            className={modal === "quests" ? "active" : ""}
            onClick={() => setModal("quests")}
            aria-label="Aufgaben"
            title="Aufgaben"
          >
            <ListChecks size={22} />
            <span>Aufgaben</span>
            {availableQuests > 0 && <i className="notification-dot" />}
          </button>
          <button
            className={modal === "inventory" ? "active" : ""}
            onClick={() => setModal("inventory")}
            aria-label="Möbellager"
            title="Möbellager"
          >
            <Warehouse size={22} />
            <span>Lager</span>
          </button>
        </div>
        <button
          className="rail-help"
          onClick={() => setModal("help")}
          aria-label="Hilfe & Spielstand"
          title="Hilfe & Spielstand"
        >
          <CircleHelp size={22} />
        </button>
      </aside>

      <div className="app-main">
        <header className="topbar">
          <a
            className="wordmark"
            href="#"
            onClick={(e) => {
              e.preventDefault();
              setModal(null);
            }}
          >
            pfotenstube<span>DEIN KLEINES HAUSTIERGLÜCK</span>
          </a>
          <div className="topbar-right">
            <div className="level-pill">
              <span className="level-icon">
                <Star size={17} fill="currentColor" />
              </span>
              <div>
                <b>Level {level}</b>
                <span className="xp-track">
                  <span style={{ width: `${game.xp % 100}%` }} />
                </span>
              </div>
              <small>{game.xp % 100}/100 XP</small>
            </div>
            <div className="wallet" aria-label={`${game.coins} Münzen`}>
              <span className="coin-icon">
                <Coins size={18} />
              </span>
              <strong data-testid="coin-count">
                {game.coins.toLocaleString("de-DE")}
              </strong>
              <span className="wallet-label">Münzen</span>
            </div>
            <button
              className={`daily-gift ${game.giftDate === dateKey(Date.now()) ? "gift-claimed" : ""}`}
              onClick={() => run(claimGift(advanceTime(game)))}
              aria-label="Tagesgeschenk abholen"
              title={
                game.giftDate === dateKey(Date.now())
                  ? "Geschenk abgeholt. Bis morgen!"
                  : "Dein Tagesgeschenk: 75 Münzen"
              }
            >
              <Gift size={21} />
              {game.giftDate !== dateKey(Date.now()) && <i />}
            </button>
          </div>
        </header>

        <main className="main-content">
          {(warning || !saved) && (
            <div className="warning-banner" role="status">
              <span>
                {!saved
                  ? "Dein Fortschritt kann gerade nicht gespeichert werden. Exportiere ihn unter Hilfe & Spielstand."
                  : warning}
              </span>
              {warning && saved && (
                <button
                  className="icon-button"
                  onClick={() => setWarning("")}
                  aria-label="Hinweis schließen"
                >
                  <X size={16} />
                </button>
              )}
            </div>
          )}
          <section className="welcome-row">
            <div>
              <div className="eyebrow">
                <Sun size={14} />
                EIN BISSCHEN GLÜCK, JEDEN TAG
              </div>
              <h1>
                Schön, dass du da bist<span>.</span>
              </h1>
              <p>Deine kleinen Lieblinge haben dich schon vermisst.</p>
            </div>
            <button
              className="button gift-button"
              onClick={() => run(claimGift(advanceTime(game)))}
              disabled={game.giftDate === dateKey(Date.now())}
            >
              <Gift size={19} />
              <span>
                {game.giftDate === dateKey(Date.now())
                  ? "Geschenk abgeholt"
                  : "Dein tägliches Geschenk"}
                <small>
                  {game.giftDate === dateKey(Date.now())
                    ? "Morgen wartet neues Glück"
                    : "+75 Münzen nur für dich"}
                </small>
              </span>
              {game.giftDate !== dateKey(Date.now()) && (
                <ArrowRight size={17} />
              )}
            </button>
          </section>

          <div className="game-layout">
            <section className="room-section" aria-labelledby="room-heading">
              <div className="section-heading">
                <div className="section-title">
                  <House size={19} />
                  <h2 id="room-heading">Dein kleines Zuhause</h2>
                  <span className="subtle-badge">
                    {game.pets.length} / {MAX_PETS} Tiere
                  </span>
                </div>
                <button
                  className={`button secondary small ${editing ? "pressed" : ""}`}
                  onClick={() => {
                    setEditing(!editing);
                    setSelectedFurniture(null);
                  }}
                  aria-pressed={editing}
                >
                  <Armchair size={16} />
                  {editing ? "Fertig" : "Einrichten"}
                </button>
              </div>
              <Room
                game={game}
                editing={editing}
                selectedFurniture={selectedFurniture}
                activity={activity}
                onSelectPet={selectPet}
                onPet={(id) => doCare("pet", id)}
                onSelectFurniture={setSelectedFurniture}
                onMove={(id, x, y) =>
                  setGame((g) => moveFurniture(g, id, x, y))
                }
                onFurnitureAction={furnitureAction}
                onDone={() => {
                  setEditing(false);
                  setSelectedFurniture(null);
                }}
              />
              <div className="room-caption">
                <span>
                  <Leaf size={14} />
                  Ein Zuhause voller kleiner Glücksmomente.
                </span>
                <span
                  className={`save-indicator ${!saved ? "save-failed" : ""}`}
                >
                  {saved ? <CheckCheck size={15} /> : <CircleHelp size={15} />}
                  {saved ? "Im Browser gespeichert" : "Nicht gespeichert"}
                </span>
              </div>

              <div className="pets-heading">
                <div>
                  <h2>
                    Deine Mitbewohner<span>{game.pets.length}</span>
                  </h2>
                  <p>Kleine Persönlichkeiten. Große Liebe.</p>
                </div>
                <button
                  className="text-button"
                  onClick={() => openShop("pets")}
                >
                  Tier adoptieren
                  <Plus size={16} />
                </button>
              </div>
              <div className="pet-roster" aria-label="Deine Tiere">
                {game.pets.map((p) => (
                  <PetCard
                    key={p.id}
                    pet={p}
                    active={p.id === game.selectedPet}
                    onClick={() => selectPet(p.id)}
                  />
                ))}
                {game.pets.length < MAX_PETS && (
                  <button
                    className="adopt-card"
                    onClick={() => openShop("pets")}
                  >
                    <span>
                      <Plus size={23} />
                    </span>
                    <b>Noch ein Plätzchen frei</b>
                    <small>Ein neuer Freund wartet auf dich</small>
                  </button>
                )}
              </div>
              <div className="bottom-note">
                <Heart size={14} />
                Ein kleines Spiel zum Runterkommen. Mach’s dir gemütlich.
              </div>
            </section>

            <aside className="care-column">
              <section className="care-card" aria-labelledby="pet-heading">
                <div className="card-eyebrow">
                  <span>
                    <span className="live-dot" />
                    DEIN LIEBLING
                  </span>
                  <button
                    className="icon-button"
                    aria-label="Tier umbenennen"
                    title="Tier umbenennen"
                    onClick={() => {
                      setPetName(selectedPet.name);
                      setModal("rename");
                    }}
                  >
                    <Pencil size={15} />
                  </button>
                </div>
                <div className="pet-portrait">
                  <span className="portrait-circle" />
                  <PetArt
                    species={selectedPet.species}
                    color={selectedPet.color}
                    accent={selectedPet.accent}
                    happy={activity?.id === selectedPet.id}
                  />
                  <span className="portrait-sparkle">✧</span>
                </div>
                <h2 id="pet-heading">
                  {selectedPet.name}
                  <Heart size={17} fill="#dfad9c" stroke="#dfad9c" />
                </h2>
                <p className="pet-description">
                  {SPECIES_LABEL[selectedPet.species]} ·{" "}
                  {Math.min(...Object.values(selectedPet.needs)) < 40
                    ? "Braucht ein bisschen Liebe"
                    : "Fühlt sich bei dir zu Hause"}
                </p>
                <div className="needs-list">
                  <NeedBar
                    label="Satt"
                    value={selectedPet.needs.hunger}
                    color="#93ad7d"
                    icon={<Utensils size={14} />}
                  />
                  <NeedBar
                    label="Glücklich"
                    value={selectedPet.needs.joy}
                    color="#d9ad6b"
                    icon={<Heart size={14} />}
                  />
                  <NeedBar
                    label="Sauber"
                    value={selectedPet.needs.clean}
                    color="#95b3bf"
                    icon={<Sparkles size={14} />}
                  />
                </div>
                <div className="care-actions">
                  <button
                    onClick={() => doCare("feed")}
                    aria-label="Füttern"
                    className="care-action"
                  >
                    <span className="action-icon food">
                      <Utensils size={21} />
                    </span>
                    <b>Füttern</b>
                    <small>−8 Münzen</small>
                  </button>
                  <button
                    onClick={() => doCare("play")}
                    aria-label="Spielen"
                    className="care-action"
                  >
                    <span className="action-icon play">
                      <Bone size={21} />
                    </span>
                    <b>Spielen</b>
                    <small>+12 Münzen</small>
                  </button>
                  <button
                    onClick={() => doCare("clean")}
                    aria-label="Pflegen"
                    className="care-action"
                  >
                    <span className="action-icon wash">
                      <Sparkles size={21} />
                    </span>
                    <b>Pflegen</b>
                    <small>+10 Münzen</small>
                  </button>
                </div>
                <p className="care-tip">
                  Gute Pflege schenkt euch beiden Glück – und dir Erfahrung.
                </p>
              </section>

              <section className="daily-card">
                <div className="daily-title">
                  <span className="daily-title-icon">
                    <ListChecks size={19} />
                  </span>
                  <div>
                    <h3>Kleine Tagesziele</h3>
                    <p>Ein bisschen Fürsorge lohnt sich.</p>
                  </div>
                  <span className="task-count">
                    {game.quests.claimed.length}/3
                  </span>
                </div>
                <div className="mini-quests">
                  {QUESTS.map((q) => {
                    const complete = game.quests.progress[q.id] > 0;
                    const claimed = game.quests.claimed.includes(q.id);
                    return (
                      <div
                        className={`mini-quest ${claimed ? "quest-claimed" : ""}`}
                        key={q.id}
                      >
                        <span
                          className={`quest-check ${complete ? "complete" : ""}`}
                        >
                          {complete && <Check size={12} />}
                        </span>
                        <span>
                          {q.id === "feed"
                            ? "Ein voller Bauch"
                            : q.id === "play"
                              ? "Gemeinsam spielen"
                              : "Eine Portion Pflege"}
                        </span>
                        {complete && !claimed ? (
                          <button
                            className="claim-mini"
                            onClick={() => run(claimQuest(game, q.id))}
                            aria-label={`${q.title}: Belohnung abholen`}
                          >
                            +{q.reward}
                            <Coins size={12} />
                          </button>
                        ) : (
                          <span className="mini-reward">
                            {claimed ? (
                              <CheckCheck size={15} />
                            ) : (
                              <>
                                <Coins size={12} />
                                {q.reward}
                              </>
                            )}
                          </span>
                        )}
                      </div>
                    );
                  })}
                </div>
                <button
                  className="all-tasks"
                  onClick={() => setModal("quests")}
                >
                  Alle Aufgaben ansehen
                  <ChevronRight size={15} />
                </button>
              </section>
            </aside>
          </div>
          <footer className="page-footer">
            <span>
              <PawPrint size={13} />
              Mit Liebe für kleine Pfoten gemacht.
            </span>
            <button onClick={() => setModal("help")}>
              So funktioniert’s
              <CircleHelp size={14} />
            </button>
          </footer>
        </main>
      </div>

      {modal === "shop" && (
        <Dialog
          wide
          title="Ein kleines Stück mehr Zuhause."
          subtitle="Neue Freunde und schöne Dinge für deine Pfotenstube."
          onClose={() => setModal(null)}
        >
          <div className="shop-toolbar">
            <div className="segmented">
              <button
                className={shopTab === "pets" ? "selected" : ""}
                onClick={() => setShopTab("pets")}
              >
                <PawPrint size={16} />
                Tiere adoptieren
              </button>
              <button
                className={shopTab === "decor" ? "selected" : ""}
                onClick={() => setShopTab("decor")}
              >
                <Armchair size={16} />
                Einrichtung
              </button>
            </div>
            <CoinPrice value={game.coins} />
          </div>
          <div className="shop-grid">
            {shopTab === "pets"
              ? PETS.map((p) => {
                  const locked = level < p.level;
                  return (
                    <article className="shop-card" key={p.id}>
                      <div className="shop-art pet-shop-art">
                        <PetArt
                          species={p.species}
                          color={p.color}
                          accent={p.accent}
                        />
                        {locked && (
                          <span className="unlock-badge">
                            <LockKeyhole size={12} />
                            Level {p.level}
                          </span>
                        )}
                      </div>
                      <span className="shop-category">
                        {SPECIES_LABEL[p.species]}
                      </span>
                      <h3>{p.name}</h3>
                      <p>{p.description}</p>
                      <button
                        className="button primary"
                        disabled={
                          locked ||
                          game.coins < p.price ||
                          game.pets.length >= MAX_PETS
                        }
                        onClick={() => {
                          if (run(adopt(game, p.id, newId()))) setModal(null);
                        }}
                        aria-label={`${p.name} adoptieren für ${p.price} Münzen`}
                      >
                        {locked ? (
                          `Ab Level ${p.level}`
                        ) : game.pets.length >= MAX_PETS ? (
                          "Stube ist voll"
                        ) : (
                          <>
                            <span>Adoptieren</span>
                            <CoinPrice value={p.price} />
                          </>
                        )}
                      </button>
                    </article>
                  );
                })
              : DECOR.map((d) => (
                  <article className="shop-card" key={d.kind}>
                    <div className="shop-art">
                      <FurnitureArt kind={d.kind} />
                    </div>
                    <span className="shop-category">FÜRS ZUHAUSE</span>
                    <h3>{d.name}</h3>
                    <p>{d.description}</p>
                    <button
                      className="button primary"
                      disabled={
                        game.coins < d.price || game.furniture.length >= 40
                      }
                      onClick={() => purchaseDecor(d.kind)}
                      aria-label={`${d.name} kaufen für ${d.price} Münzen`}
                    >
                      <span>Kaufen</span>
                      <CoinPrice value={d.price} />
                    </button>
                  </article>
                ))}
          </div>
          <p className="modal-footnote">
            <Heart size={14} />
            Du verdienst Münzen beim Spielen, Pflegen und mit deinen
            Tageszielen.
          </p>
        </Dialog>
      )}

      {modal === "quests" && (
        <Dialog
          title="Kleine Ziele, große Freude."
          subtitle="Jeden Tag neue Gelegenheiten, etwas Gutes zu tun."
          onClose={() => setModal(null)}
        >
          <div className="quest-list">
            {QUESTS.map((q) => (
              <div className="quest-item" key={q.id}>
                <span
                  className={`quest-icon ${game.quests.progress[q.id] ? "done" : ""}`}
                >
                  {q.id === "feed" ? (
                    <Utensils size={22} />
                  ) : q.id === "play" ? (
                    <Bone size={22} />
                  ) : (
                    <Sparkles size={22} />
                  )}
                </span>
                <div>
                  <h3>{q.title}</h3>
                  <p>{q.detail}</p>
                  <small>
                    <Coins size={12} />
                    {q.reward} Münzen · 20 XP
                  </small>
                </div>
                <button
                  className={`button small ${game.quests.progress[q.id] && !game.quests.claimed.includes(q.id) ? "primary" : "secondary"}`}
                  disabled={
                    !game.quests.progress[q.id] ||
                    game.quests.claimed.includes(q.id)
                  }
                  onClick={() => run(claimQuest(game, q.id))}
                >
                  {game.quests.claimed.includes(q.id) ? (
                    <CheckCheck size={18} />
                  ) : (
                    "Abholen"
                  )}
                </button>
              </div>
            ))}
          </div>
          <p className="modal-footnote">
            Deine Aufgaben erneuern sich um Mitternacht nach deiner Ortszeit.
          </p>
        </Dialog>
      )}

      {modal === "inventory" && (
        <Dialog
          wide
          title="Deine kleinen Schätze."
          subtitle="Eingelagerte Möbel kannst du jederzeit kostenlos wieder aufstellen."
          onClose={() => setModal(null)}
        >
          <div className="shop-grid inventory-grid">
            {game.furniture
              .filter((f) => !f.placed)
              .map((f) => (
                <article className="shop-card" key={f.id}>
                  <div className="shop-art">
                    <FurnitureArt kind={f.kind} />
                  </div>
                  <h3>{DECOR.find((d) => d.kind === f.kind)?.name}</h3>
                  <button
                    className="button primary"
                    onClick={() => restoreFurniture(f.id)}
                  >
                    Aufstellen
                    <Plus size={15} />
                  </button>
                </article>
              ))}
          </div>
          {!game.furniture.some((f) => !f.placed) && (
            <div className="empty-state">
              <Warehouse size={45} strokeWidth={1.3} />
              <h3>Alles hat schon seinen Platz.</h3>
              <p>
                Lagere Möbel im Einrichtungsmodus ein. Hier warten sie auf ihren
                nächsten Auftritt.
              </p>
              <button
                className="button primary"
                onClick={() => openShop("decor")}
              >
                Einrichtung entdecken
                <ArrowRight size={16} />
              </button>
            </div>
          )}
        </Dialog>
      )}

      {modal === "rename" && (
        <Dialog
          title="Ein Name voller Liebe."
          subtitle="Wie soll dein kleiner Liebling heißen?"
          onClose={() => setModal(null)}
        >
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (run(renamePet(game, game.selectedPet, petName)))
                setModal(null);
            }}
          >
            <label className="input-label" htmlFor="pet-name">
              Name deines Tiers
            </label>
            <input
              id="pet-name"
              className="name-input"
              value={petName}
              onChange={(e) => setPetName(e.target.value)}
              maxLength={18}
              required
              autoFocus
            />
            <div className="form-footer">
              <span>{petName.length}/18 Zeichen</span>
              <button className="button primary" type="submit">
                Namen speichern
                <Check size={16} />
              </button>
            </div>
          </form>
        </Dialog>
      )}

      {modal === "help" && (
        <Dialog
          title="Willkommen in der Pfotenstube."
          subtitle="Deine kleine Auszeit mit ziemlich viel Fell."
          onClose={() => setModal(null)}
        >
          <div className="help-steps">
            <div>
              <span>
                <PawPrint size={21} />
              </span>
              <p>
                <b>Ein Herz für deine Tiere.</b> Wähle einen Mitbewohner aus.
                Füttere ihn, spiele mit ihm oder gönne ihm ein bisschen Pflege.
                Ein Klick im Zimmer ist eine Streicheleinheit.
              </p>
            </div>
            <div>
              <span>
                <Coins size={21} />
              </span>
              <p>
                <b>Kleine Schritte, neues Glück.</b> Spielen und Pflegen bringen
                Münzen. Futter kostet 8 Münzen. Hole dir Tagesbelohnungen,
                sammle XP und schalte neue Tiere frei.
              </p>
            </div>
            <div>
              <span>
                <Armchair size={21} />
              </span>
              <p>
                <b>Mach es zu eurem Zuhause.</b> Im Laden findest du Möbel und
                neue Freunde. Im Einrichtungsmodus kannst du Möbel ziehen oder
                mit den Pfeiltasten bewegen, drehen und einlagern.
              </p>
            </div>
            <div>
              <span>
                <Heart size={21} />
              </span>
              <p>
                <b>Ganz in deinem Tempo.</b> Bedürfnisse sinken langsam, auch
                während einer Pause (höchstens acht Stunden). Deine Tiere können
                nicht sterben. Es gibt keine Käufe mit echtem Geld.
              </p>
            </div>
          </div>
          <div className="save-box">
            <h3>Dein Spielstand gehört dir.</h3>
            <p>
              Er wird in diesem Browser gespeichert. Sichere ihn als Datei,
              bevor du Browserdaten löschst oder das Gerät wechselst. Ein Import
              ersetzt deinen aktuellen Fortschritt nach Bestätigung.
            </p>
            <div className="save-buttons">
              <button className="button secondary" onClick={downloadSave}>
                <ArrowDownToLine size={16} />
                Spielstand exportieren
              </button>
              <label className="button secondary import-button">
                <Plus size={16} />
                Spielstand importieren
                <input
                  type="file"
                  accept="application/json,.json"
                  aria-label="Spielstand importieren"
                  onChange={(e) => {
                    void importSave(e.target.files?.[0]);
                    e.target.value = "";
                  }}
                />
              </label>
            </div>
          </div>
          <p className="modal-footnote">
            Pfotenstube · Ein eigenständiger Prototyp, inspiriert von
            klassischen Haustierspielen. Ohne Facebook-Verbindung.
          </p>
        </Dialog>
      )}

      <div
        className="toast-container"
        role="status"
        aria-live="polite"
        aria-atomic="true"
      >
        {toast && (
          <div className={`toast ${toast.success ? "" : "toast-info"}`}>
            <span>
              {toast.success ? <Check size={18} /> : <CircleHelp size={18} />}
            </span>
            <p>{toast.text}</p>
            <button
              className="icon-button"
              onClick={() => setToast(null)}
              aria-label="Nachricht schließen"
            >
              <X size={16} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function PetCard({
  pet,
  active,
  onClick,
}: {
  pet: Pet;
  active: boolean;
  onClick: () => void;
}) {
  const mood = Math.min(...Object.values(pet.needs));
  return (
    <button
      className={`pet-card ${active ? "active" : ""}`}
      onClick={onClick}
      aria-label={`${pet.name} auswählen`}
      aria-pressed={active}
    >
      <span className="roster-art">
        <PetArt species={pet.species} color={pet.color} accent={pet.accent} />
      </span>
      <span className="roster-info">
        <b>{pet.name}</b>
        <small>{SPECIES_LABEL[pet.species]}</small>
        <span className={`mood-label ${mood < 40 ? "mood-low" : ""}`}>
          <span />
          {mood < 40 ? "Braucht Fürsorge" : "Fühlt sich wohl"}
        </span>
      </span>
      {active && (
        <span className="roster-check">
          <Check size={12} />
        </span>
      )}
    </button>
  );
}
