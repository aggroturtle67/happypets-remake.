export type Species = "cat" | "dog" | "bunny";
export type Action = "feed" | "play" | "clean" | "pet";
export type Needs = { hunger: number; joy: number; clean: number };
export type Pet = {
  id: string;
  name: string;
  species: Species;
  color: string;
  accent: string;
  needs: Needs;
};
export type FurnitureKind =
  | "bed"
  | "plant"
  | "scratch"
  | "rug"
  | "bowl"
  | "cushion"
  | "lamp"
  | "toys";
export type Furniture = {
  id: string;
  kind: FurnitureKind;
  x: number;
  y: number;
  placed: boolean;
  flipped: boolean;
};
export type QuestKey = "feed" | "play" | "clean";
export type Game = {
  version: 1;
  coins: number;
  xp: number;
  pets: Pet[];
  furniture: Furniture[];
  selectedPet: string;
  lastUpdated: number;
  giftDate: string;
  quests: {
    date: string;
    progress: Record<QuestKey, number>;
    claimed: QuestKey[];
  };
};
export type Result = { game: Game; message: string; success: boolean };

export const STORAGE_KEY = "pfotenstube.save.v1";
export const MAX_PETS = 6;
export const levelOf = (xp: number) => Math.floor(xp / 100) + 1;
export const dateKey = (now: number) => {
  const d = new Date(now);
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
};
export const SPECIES_LABEL: Record<Species, string> = {
  cat: "Katze",
  dog: "Hund",
  bunny: "Kaninchen",
};
export const PETS: {
  id: string;
  name: string;
  species: Species;
  color: string;
  accent: string;
  price: number;
  level: number;
  description: string;
}[] = [
  {
    id: "peach",
    name: "Pfirsich",
    species: "cat",
    color: "#e8ae70",
    accent: "#c68c51",
    price: 120,
    level: 1,
    description: "Kleine Pfoten, große Neugier.",
  },
  {
    id: "cocoa",
    name: "Kakao",
    species: "dog",
    color: "#b68a6d",
    accent: "#78533f",
    price: 160,
    level: 1,
    description: "Dein neuer bester Freund.",
  },
  {
    id: "cloud",
    name: "Wölkchen",
    species: "bunny",
    color: "#f1ede5",
    accent: "#d9b4b7",
    price: 180,
    level: 2,
    description: "Ein flauschiges Stück Glück.",
  },
  {
    id: "pepper",
    name: "Pfeffer",
    species: "cat",
    color: "#839092",
    accent: "#56676b",
    price: 150,
    level: 1,
    description: "Samtpfote mit eigenem Kopf.",
  },
];
export const DECOR: {
  kind: FurnitureKind;
  name: string;
  price: number;
  description: string;
}[] = [
  {
    kind: "bed",
    name: "Kuschelkörbchen",
    price: 65,
    description: "Für die schönsten Träume.",
  },
  {
    kind: "plant",
    name: "Zimmergrün",
    price: 35,
    description: "Ein kleines bisschen Dschungel.",
  },
  {
    kind: "scratch",
    name: "Kratzbaum",
    price: 80,
    description: "Klettern. Kratzen. König sein.",
  },
  {
    kind: "rug",
    name: "Sonnenteppich",
    price: 50,
    description: "Ein warmer Platz für alle.",
  },
  {
    kind: "bowl",
    name: "Futternäpfe",
    price: 25,
    description: "Hier schmeckt’s am besten.",
  },
  {
    kind: "cushion",
    name: "Wolkenkissen",
    price: 40,
    description: "Noch fünf Minuten …",
  },
  {
    kind: "lamp",
    name: "Leselämpchen",
    price: 55,
    description: "Warmes Licht, gute Laune.",
  },
  {
    kind: "toys",
    name: "Spielzeugkiste",
    price: 45,
    description: "Ein ganzer Korb Abenteuer.",
  },
];
export const QUESTS: {
  id: QuestKey;
  title: string;
  detail: string;
  reward: number;
}[] = [
  {
    id: "feed",
    title: "Liebe geht durch den Magen",
    detail: "Füttere eines deiner Tiere.",
    reward: 30,
  },
  {
    id: "play",
    title: "Zeit für eine Spielrunde",
    detail: "Spiele mit einem deiner Tiere.",
    reward: 35,
  },
  {
    id: "clean",
    title: "Frisch & flauschig",
    detail: "Verwöhne ein Tier mit Pflege.",
    reward: 30,
  },
];

export function newGame(now = Date.now()): Game {
  return {
    version: 1,
    coins: 280,
    xp: 0,
    pets: [
      {
        id: "momo",
        name: "Momo",
        species: "cat",
        color: "#e8ae70",
        accent: "#c68c51",
        needs: { hunger: 62, joy: 72, clean: 80 },
      },
      {
        id: "milo",
        name: "Milo",
        species: "dog",
        color: "#e5d0b2",
        accent: "#9f765b",
        needs: { hunger: 75, joy: 58, clean: 65 },
      },
    ],
    furniture: [
      {
        id: "rug-start",
        kind: "rug",
        x: 50,
        y: 88,
        placed: true,
        flipped: false,
      },
      {
        id: "bed-start",
        kind: "bed",
        x: 23,
        y: 67,
        placed: true,
        flipped: false,
      },
      {
        id: "plant-start",
        kind: "plant",
        x: 89,
        y: 63,
        placed: true,
        flipped: false,
      },
      {
        id: "scratch-start",
        kind: "scratch",
        x: 72,
        y: 62,
        placed: true,
        flipped: false,
      },
      {
        id: "bowl-start",
        kind: "bowl",
        x: 20,
        y: 89,
        placed: true,
        flipped: false,
      },
      {
        id: "toys-start",
        kind: "toys",
        x: 84,
        y: 87,
        placed: true,
        flipped: false,
      },
    ],
    selectedPet: "momo",
    lastUpdated: now,
    giftDate: "",
    quests: {
      date: dateKey(now),
      progress: { feed: 0, play: 0, clean: 0 },
      claimed: [],
    },
  };
}

const clamp = (n: number, min = 0, max = 100) =>
  Math.max(min, Math.min(max, n));
const fail = (game: Game, message: string): Result => ({
  game,
  message,
  success: false,
});

export function advanceTime(game: Game, now = Date.now()): Game {
  const minutes = Math.max(0, Math.min((now - game.lastUpdated) / 60_000, 480));
  return {
    ...game,
    lastUpdated: now,
    pets: game.pets.map((p) => ({
      ...p,
      needs: {
        hunger: clamp(p.needs.hunger - minutes * 0.3),
        joy: clamp(p.needs.joy - minutes * 0.2),
        clean: clamp(p.needs.clean - minutes * 0.15),
      },
    })),
    quests:
      game.quests.date === dateKey(now)
        ? game.quests
        : {
            date: dateKey(now),
            progress: { feed: 0, play: 0, clean: 0 },
            claimed: [],
          },
  };
}

export function care(game: Game, id: string, action: Action): Result {
  const pet = game.pets.find((p) => p.id === id);
  if (!pet) return fail(game, "Wähle zuerst ein Tier aus.");
  const settings = {
    feed: { need: "hunger", amount: 35, coins: -8, xp: 15 },
    play: { need: "joy", amount: 30, coins: 12, xp: 20 },
    clean: { need: "clean", amount: 35, coins: 10, xp: 15 },
    pet: { need: "joy", amount: 8, coins: 0, xp: 3 },
  } as const;
  const spec = settings[action];
  if (pet.needs[spec.need] > (action === "pet" ? 95 : 85))
    return fail(
      game,
      `${pet.name} ist schon bestens versorgt. Versuch es später wieder!`,
    );
  if (game.coins + spec.coins < 0)
    return fail(
      game,
      "Dir fehlen Münzen fürs Futter. Beim Spielen und Pflegen verdienst du neue.",
    );
  const progress = { ...game.quests.progress };
  if (action !== "pet") progress[action] = 1;
  const messages: Record<Action, string> = {
    feed: `${pet.name} lässt es sich schmecken! +15 XP`,
    play: `${pet.name} hat riesigen Spaß! +12 Münzen · +20 XP`,
    clean: `${pet.name} ist wieder blitzsauber! +10 Münzen · +15 XP`,
    pet: `${pet.name} genießt die Streicheleinheit. +3 XP`,
  };
  return {
    success: true,
    message: messages[action],
    game: {
      ...game,
      coins: game.coins + spec.coins,
      xp: game.xp + spec.xp,
      pets: game.pets.map((p) =>
        p.id === id
          ? {
              ...p,
              needs: {
                ...p.needs,
                [spec.need]: clamp(p.needs[spec.need] + spec.amount),
              },
            }
          : p,
      ),
      quests: { ...game.quests, progress },
    },
  };
}

export function adopt(game: Game, catalogId: string, id: string): Result {
  const item = PETS.find((p) => p.id === catalogId);
  if (!item) return fail(game, "Dieses Tier ist gerade nicht verfügbar.");
  if (game.pets.length >= MAX_PETS)
    return fail(
      game,
      "Deine Stube ist voll. Bis zu sechs Tiere können hier wohnen.",
    );
  if (levelOf(game.xp) < item.level)
    return fail(game, `Dieses Tier zieht ab Level ${item.level} bei dir ein.`);
  if (game.coins < item.price)
    return fail(
      game,
      "Dafür fehlen dir noch ein paar Münzen. Erledige die Tagesaufgaben!",
    );
  const pet: Pet = {
    id,
    name: item.name,
    species: item.species,
    color: item.color,
    accent: item.accent,
    needs: { hunger: 70, joy: 75, clean: 85 },
  };
  return {
    success: true,
    message: `Willkommen zu Hause, ${pet.name}!`,
    game: {
      ...game,
      pets: [...game.pets, pet],
      coins: game.coins - item.price,
      xp: game.xp + 20,
      selectedPet: id,
    },
  };
}

export function buyDecor(game: Game, kind: FurnitureKind, id: string): Result {
  const item = DECOR.find((d) => d.kind === kind);
  if (!item) return fail(game, "Dieser Gegenstand ist nicht verfügbar.");
  if (game.furniture.length >= 40)
    return fail(game, "Dein Möbellager ist voll (40 Gegenstände).");
  if (game.coins < item.price)
    return fail(game, "Dafür fehlen dir noch ein paar Münzen.");
  return {
    success: true,
    message: `${item.name} ist da! Ziehe es an deinen Lieblingsplatz.`,
    game: {
      ...game,
      coins: game.coins - item.price,
      furniture: [
        ...game.furniture,
        {
          id,
          kind,
          x: 50,
          y: kind === "rug" ? 88 : 72,
          placed: true,
          flipped: false,
        },
      ],
    },
  };
}

export function moveFurniture(
  game: Game,
  id: string,
  x: number,
  y: number,
): Game {
  if (!Number.isFinite(x) || !Number.isFinite(y)) return game;
  return {
    ...game,
    furniture: game.furniture.map((f) =>
      f.id === id ? { ...f, x: clamp(x, 8, 92), y: clamp(y, 54, 91) } : f,
    ),
  };
}

export function claimQuest(game: Game, key: QuestKey): Result {
  const quest = QUESTS.find((q) => q.id === key);
  if (!quest || !game.quests.progress[key] || game.quests.claimed.includes(key))
    return fail(game, "Diese Belohnung ist noch nicht verfügbar.");
  return {
    success: true,
    message: `Tagesaufgabe geschafft! +${quest.reward} Münzen · +20 XP`,
    game: {
      ...game,
      coins: game.coins + quest.reward,
      xp: game.xp + 20,
      quests: { ...game.quests, claimed: [...game.quests.claimed, key] },
    },
  };
}

export function claimGift(game: Game, now = Date.now()): Result {
  if (game.giftDate === dateKey(now))
    return fail(game, "Dein nächstes Geschenk wartet morgen auf dich.");
  return {
    success: true,
    message: "Schön, dass du da bist! +75 Münzen",
    game: { ...game, coins: game.coins + 75, giftDate: dateKey(now) },
  };
}

export function renamePet(game: Game, id: string, name: string): Result {
  const cleaned = name.trim().slice(0, 18);
  if (!cleaned) return fail(game, "Gib deinem Tier einen Namen.");
  return {
    success: true,
    message: `Ein schöner Name: ${cleaned}!`,
    game: {
      ...game,
      pets: game.pets.map((p) => (p.id === id ? { ...p, name: cleaned } : p)),
    },
  };
}

/** Saves are untrusted input. Reject partial/corrupt/unknown data instead of crashing the room. */
export function parseSave(raw: string): Game | null {
  try {
    const g = JSON.parse(raw) as Game;
    const numeric = (n: unknown, min: number, max: number): n is number =>
      typeof n === "number" && Number.isFinite(n) && n >= min && n <= max;
    const text = (s: unknown, max: number): s is string =>
      typeof s === "string" && s.length > 0 && s.length <= max;
    const color = (s: unknown) =>
      typeof s === "string" && /^#[0-9a-f]{6}$/i.test(s);
    if (
      !g ||
      g.version !== 1 ||
      !numeric(g.coins, 0, 1e9) ||
      !numeric(g.xp, 0, 1e9) ||
      !numeric(g.lastUpdated, 0, 1e14)
    )
      return null;
    if (
      !Array.isArray(g.pets) ||
      g.pets.length < 1 ||
      g.pets.length > MAX_PETS ||
      !Array.isArray(g.furniture) ||
      g.furniture.length > 40
    )
      return null;
    if (
      !g.pets.every(
        (p) =>
          p &&
          text(p.id, 100) &&
          text(p.name, 18) &&
          ["cat", "dog", "bunny"].includes(p.species) &&
          color(p.color) &&
          color(p.accent) &&
          p.needs &&
          ["hunger", "joy", "clean"].every((k) =>
            numeric(p.needs[k as keyof Needs], 0, 100),
          ),
      )
    )
      return null;
    if (
      new Set(g.pets.map((p) => p.id)).size !== g.pets.length ||
      !g.pets.some((p) => p.id === g.selectedPet)
    )
      return null;
    if (
      !g.furniture.every(
        (f) =>
          f &&
          text(f.id, 100) &&
          DECOR.some((d) => d.kind === f.kind) &&
          numeric(f.x, 8, 92) &&
          numeric(f.y, 54, 91) &&
          typeof f.placed === "boolean" &&
          typeof f.flipped === "boolean",
      )
    )
      return null;
    if (new Set(g.furniture.map((f) => f.id)).size !== g.furniture.length)
      return null;
    if (
      typeof g.giftDate !== "string" ||
      !g.quests ||
      typeof g.quests.date !== "string" ||
      !g.quests.progress ||
      !Array.isArray(g.quests.claimed)
    )
      return null;
    if (
      !QUESTS.every((q) => numeric(g.quests.progress[q.id], 0, 1)) ||
      !g.quests.claimed.every((k) => QUESTS.some((q) => q.id === k)) ||
      new Set(g.quests.claimed).size !== g.quests.claimed.length
    )
      return null;
    return g;
  } catch {
    return null;
  }
}
