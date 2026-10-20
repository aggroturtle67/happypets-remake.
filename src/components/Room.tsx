import { useEffect, useRef, useState } from "react";
import { Check, Hand, Move, RotateCw, Warehouse } from "lucide-react";
import { DECOR, type Furniture, type Game } from "../game";
import { FurnitureArt, PetArt, RoomBackdrop } from "./Art";

type Props = {
  game: Game;
  editing: boolean;
  selectedFurniture: string | null;
  activity: { id: string; text: string; key: number } | null;
  onSelectPet: (id: string) => void;
  onPet: (id: string) => void;
  onSelectFurniture: (id: string) => void;
  onMove: (id: string, x: number, y: number) => void;
  onFurnitureAction: (action: "flip" | "store") => void;
  onDone: () => void;
};

export default function Room({
  game,
  editing,
  selectedFurniture,
  activity,
  onSelectPet,
  onPet,
  onSelectFurniture,
  onMove,
  onFurnitureAction,
  onDone,
}: Props) {
  const room = useRef<HTMLDivElement>(null);
  const drag = useRef<{ id: string; dx: number; dy: number } | null>(null);
  const [positions, setPositions] = useState<
    Record<string, { x: number; y: number }>
  >({});
  useEffect(() => {
    const timer = window.setInterval(() => {
      if (editing) return;
      setPositions((previous) =>
        Object.fromEntries(
          game.pets.map((p, i) => [
            p.id,
            activity?.id === p.id
              ? (previous[p.id] ?? { x: 42 + i * 15, y: 78 + i * 5 })
              : { x: 30 + Math.random() * 46, y: 67 + Math.random() * 23 },
          ]),
        ),
      );
    }, 6500);
    return () => clearInterval(timer);
  }, [game.pets, editing, activity]);

  function beginDrag(
    event: React.PointerEvent<HTMLButtonElement>,
    f: Furniture,
  ) {
    if (!editing || !room.current) return;
    event.preventDefault();
    const box = room.current.getBoundingClientRect();
    drag.current = {
      id: f.id,
      dx: ((event.clientX - box.left) / box.width) * 100 - f.x,
      dy: ((event.clientY - box.top) / box.height) * 100 - f.y,
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    onSelectFurniture(f.id);
  }
  function moveDrag(event: React.PointerEvent<HTMLButtonElement>) {
    if (!drag.current || !room.current) return;
    const box = room.current.getBoundingClientRect();
    onMove(
      drag.current.id,
      ((event.clientX - box.left) / box.width) * 100 - drag.current.dx,
      ((event.clientY - box.top) / box.height) * 100 - drag.current.dy,
    );
  }
  const selected = game.furniture.find((f) => f.id === selectedFurniture);

  return (
    <div className={`room-frame ${editing ? "is-editing" : ""}`}>
      <div className="room-scene" ref={room} aria-label="Dein Haustierzimmer">
        <RoomBackdrop />
        <div className="room-tag">
          <span className="live-dot" />
          {editing ? "Einrichtungsmodus" : "Zuhause ist es am schönsten"}
        </div>
        {editing && <div className="floor-grid" />}
        {game.furniture
          .filter((f) => f.placed)
          .map((f) => (
            <button
              key={f.id}
              className={`room-furniture furniture-${f.kind} ${selectedFurniture === f.id && editing ? "furniture-selected" : ""}`}
              style={{
                left: `${f.x}%`,
                top: `${f.y}%`,
                zIndex: f.kind === "rug" ? 1 : Math.floor(f.y),
                pointerEvents: editing ? "auto" : "none",
              }}
              aria-label={`${DECOR.find((d) => d.kind === f.kind)?.name} verschieben`}
              tabIndex={editing ? 0 : -1}
              onPointerDown={(e) => beginDrag(e, f)}
              onPointerMove={moveDrag}
              onPointerUp={() => {
                drag.current = null;
              }}
              onPointerCancel={() => {
                drag.current = null;
              }}
              onClick={() => onSelectFurniture(f.id)}
              onKeyDown={(e) => {
                const moves: Record<string, [number, number]> = {
                  ArrowLeft: [-2, 0],
                  ArrowRight: [2, 0],
                  ArrowUp: [0, -2],
                  ArrowDown: [0, 2],
                };
                const delta = moves[e.key];
                if (editing && delta) {
                  e.preventDefault();
                  onSelectFurniture(f.id);
                  onMove(f.id, f.x + delta[0], f.y + delta[1]);
                }
              }}
            >
              <span
                style={{
                  display: "block",
                  transform: f.flipped ? "scaleX(-1)" : undefined,
                }}
              >
                <FurnitureArt kind={f.kind} />
              </span>
              {editing && (
                <span className="furniture-move-icon">
                  <Move size={15} />
                </span>
              )}
            </button>
          ))}
        {game.pets.map((p, i) => {
          const pos = positions[p.id] ?? {
            x: 43 + (i % 3) * 17,
            y: 77 + Math.floor(i / 3) * 10 + (i % 2) * 7,
          };
          const active = activity?.id === p.id;
          return (
            <button
              key={p.id}
              className={`room-pet ${game.selectedPet === p.id ? "pet-selected" : ""} ${active ? "is-active" : ""}`}
              style={{
                left: `${pos.x}%`,
                top: `${pos.y}%`,
                zIndex: Math.floor(pos.y),
                pointerEvents: editing ? "none" : "auto",
              }}
              aria-label={`${p.name} streicheln`}
              tabIndex={editing ? -1 : 0}
              onClick={() => {
                onSelectPet(p.id);
                onPet(p.id);
              }}
            >
              {active && (
                <span className="pet-bubble" key={activity.key}>
                  {activity.text}
                </span>
              )}
              {!active && p.needs.hunger < 40 && (
                <span className="pet-bubble need-bubble">Hunger …</span>
              )}
              <span className="pet-sprite">
                <PetArt
                  species={p.species}
                  color={p.color}
                  accent={p.accent}
                  happy={active}
                />
              </span>
              <span className="pet-name">
                {p.name}
                {game.selectedPet === p.id && <span>♥</span>}
              </span>
            </button>
          );
        })}
        {!editing && (
          <div className="room-hint">
            <Hand size={14} />
            Klicke ein Tier zum Streicheln
          </div>
        )}
      </div>
      {editing && (
        <div className="edit-bar">
          <div>
            <Move size={18} />
            <span>
              {selected
                ? DECOR.find((d) => d.kind === selected.kind)?.name
                : "Möbel ziehen oder mit Pfeiltasten verschieben"}
            </span>
          </div>
          <div>
            {selected && (
              <>
                <button
                  className="icon-button"
                  title="Drehen"
                  aria-label="Möbel drehen"
                  onClick={() => onFurnitureAction("flip")}
                >
                  <RotateCw size={17} />
                </button>
                <button
                  className="icon-button"
                  title="Einlagern"
                  aria-label="Möbel einlagern"
                  onClick={() => onFurnitureAction("store")}
                >
                  <Warehouse size={17} />
                </button>
              </>
            )}
            <button className="button primary small" onClick={onDone}>
              <Check size={16} />
              Fertig
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
