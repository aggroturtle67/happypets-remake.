import { describe, expect, it } from "vitest";
import {
  adopt,
  advanceTime,
  buyDecor,
  care,
  claimGift,
  claimQuest,
  dateKey,
  MAX_PETS,
  moveFurniture,
  newGame,
  parseSave,
  renamePet,
} from "./game";

const NOW = new Date(2026, 9, 20, 12).getTime();
describe("Pfotenstube game rules", () => {
  it("feeds only the selected animal and charges food exactly once", () => {
    const game = newGame(NOW);
    const result = care(game, "momo", "feed");
    expect(result.success).toBe(true);
    expect(result.game.coins).toBe(272);
    expect(result.game.pets[0].needs.hunger).toBe(97);
    expect(result.game.pets[1]).toEqual(game.pets[1]);
    expect(result.game.quests.progress.feed).toBe(1);
    const repeated = care(result.game, "momo", "feed");
    expect(repeated.success).toBe(false);
    expect(repeated.game).toEqual(result.game);
    expect(game.pets[0].needs.hunger).toBe(62);
  });
  it("earns coins through play but cannot farm rewards from a fully happy pet", () => {
    const game = newGame(NOW);
    const first = care(game, "milo", "play");
    expect(first.game.coins).toBe(292);
    expect(first.game.xp).toBe(20);
    expect(first.game.pets[1].needs.joy).toBe(88);
    expect(care(first.game, "milo", "play").success).toBe(false);
  });
  it("rejects food and shop purchases when coins are insufficient", () => {
    const game = { ...newGame(NOW), coins: 0 };
    expect(care(game, "momo", "feed").game).toEqual(game);
    expect(adopt(game, "peach", "new-cat").success).toBe(false);
    expect(buyDecor(game, "bed", "new-bed").success).toBe(false);
    expect(care(game, "milo", "play").success).toBe(true);
  });
  it("enforces adoption prices, level unlocks and room capacity", () => {
    const game = newGame(NOW);
    expect(adopt(game, "cloud", "bunny").success).toBe(false);
    const cat = adopt(game, "peach", "new-cat");
    expect(cat.game.pets).toHaveLength(3);
    expect(cat.game.coins).toBe(160);
    expect(cat.game.selectedPet).toBe("new-cat");
    const bunny = adopt({ ...game, xp: 100 }, "cloud", "new-bunny");
    expect(bunny.success).toBe(true);
    expect(bunny.game.pets[2].species).toBe("bunny");
    const full = {
      ...game,
      pets: Array.from({ length: MAX_PETS }, (_, i) => ({
        ...game.pets[0],
        id: `cat-${i}`,
      })),
    };
    expect(adopt(full, "peach", "extra").success).toBe(false);
  });
  it("grants each completed quest exactly once", () => {
    const initial = newGame(NOW);
    expect(claimQuest(initial, "feed").success).toBe(false);
    const fed = care(initial, "momo", "feed").game;
    const reward = claimQuest(fed, "feed");
    expect(reward.game.coins).toBe(fed.coins + 30);
    expect(reward.game.xp).toBe(fed.xp + 20);
    expect(claimQuest(reward.game, "feed").success).toBe(false);
  });
  it("resets daily quests and gifts by local calendar day, not elapsed hours", () => {
    const game = newGame(NOW);
    const gifted = claimGift(game, NOW);
    expect(gifted.game.coins).toBe(355);
    expect(claimGift(gifted.game, NOW + 1000).success).toBe(false);
    const claimed = claimQuest(
      care(gifted.game, "momo", "feed").game,
      "feed",
    ).game;
    const tomorrow = advanceTime(claimed, NOW + 86_400_000);
    expect(tomorrow.quests.claimed).toEqual([]);
    expect(tomorrow.quests.progress.feed).toBe(0);
    expect(tomorrow.quests.date).toBe(dateKey(NOW + 86_400_000));
    expect(claimGift(tomorrow, NOW + 86_400_000).success).toBe(true);
  });
  it("applies offline decay with an eight-hour cap and never negative stats", () => {
    const game = newGame(NOW);
    const short = advanceTime(game, NOW + 60_000);
    expect(short.pets[0].needs.hunger).toBeCloseTo(61.7);
    const day = advanceTime(game, NOW + 24 * 60 * 60_000);
    const week = advanceTime(game, NOW + 7 * 24 * 60 * 60_000);
    expect(day.pets[0].needs).toEqual(week.pets[0].needs);
    expect(day.pets[0].needs.hunger).toBe(0);
    expect(advanceTime(game, NOW - 60_000).pets[0].needs).toEqual(
      game.pets[0].needs,
    );
  });
  it("places purchased furniture inside the room and clamps dragging coordinates", () => {
    const game = newGame(NOW);
    const result = buyDecor(game, "plant", "my-plant");
    expect(result.game.coins).toBe(245);
    expect(result.game.furniture.at(-1)?.placed).toBe(true);
    const moved = moveFurniture(result.game, "my-plant", -50, 200);
    expect(moved.furniture.at(-1)).toMatchObject({ x: 8, y: 91 });
    expect(moveFurniture(moved, "my-plant", NaN, 60)).toEqual(moved);
  });
  it("round-trips valid saves and rejects corrupt, partial, unknown and unsafe data", () => {
    const game = newGame(NOW);
    expect(parseSave(JSON.stringify(game))).toEqual(game);
    const invalid = [
      null,
      {},
      { ...game, version: 2 },
      { ...game, coins: -1 },
      { ...game, selectedPet: "missing" },
      { ...game, pets: [] },
      {
        ...game,
        pets: [{ ...game.pets[0], color: "url(javascript:alert(1))" }],
      },
      { ...game, furniture: [{ ...game.furniture[0], x: 1000 }] },
      { ...game, quests: { ...game.quests, progress: {} } },
    ];
    for (const save of invalid)
      expect(parseSave(JSON.stringify(save))).toBeNull();
    expect(parseSave("{broken")).toBeNull();
  });
  it("trims pet names and does not accept an empty name", () => {
    const game = newGame(NOW);
    expect(renamePet(game, "momo", "   ").success).toBe(false);
    expect(renamePet(game, "momo", "  Keks  ").game.pets[0].name).toBe("Keks");
  });
});
