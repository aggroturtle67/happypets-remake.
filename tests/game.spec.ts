import { expect, test, type Page } from "@playwright/test";
import { readFile } from "node:fs/promises";

const SAVE = "pfotenstube.save.v1";
const pageErrors = new WeakMap<Page, string[]>();
test.beforeEach(async ({ page }) => {
  const errors: string[] = [];
  pageErrors.set(page, errors);
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("/");
});
test.afterEach(async ({ page }) => {
  expect(pageErrors.get(page)).toEqual([]);
});

test("care, quest rewards and names survive a page reload", async ({
  page,
}) => {
  await expect(
    page.getByRole("heading", { name: "Schön, dass du da bist." }),
  ).toBeVisible();
  await expect(page.getByTestId("coin-count")).toHaveText("280");
  await page.getByRole("button", { name: "Füttern", exact: true }).click();
  await expect(
    page.getByRole("progressbar", { name: "Satt", exact: true }),
  ).toHaveAttribute("aria-valuenow", "97");
  await expect(page.getByTestId("coin-count")).toHaveText("272");
  await page
    .getByRole("button", {
      name: "Liebe geht durch den Magen: Belohnung abholen",
    })
    .click();
  await expect(page.getByTestId("coin-count")).toHaveText("302");
  await page.getByRole("button", { name: "Tier umbenennen" }).click();
  await page.getByLabel("Name deines Tiers").fill("Keks");
  await page.getByRole("button", { name: "Namen speichern" }).click();
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Keks", exact: true }),
  ).toBeVisible();
  await expect(page.getByTestId("coin-count")).toHaveText("302");
  const saved = await page.evaluate(
    (key) => JSON.parse(localStorage.getItem(key)!),
    SAVE,
  );
  expect(saved.quests.claimed).toContain("feed");
});

test("adoption is a real purchase and selects the new pet", async ({
  page,
}) => {
  await page.getByRole("button", { name: "Laden", exact: true }).click();
  await expect(page.getByRole("dialog")).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Wölkchen adoptieren für 180 Münzen" }),
  ).toBeDisabled();
  await page
    .getByRole("button", { name: "Pfirsich adoptieren für 120 Münzen" })
    .click();
  await expect(page.getByRole("dialog")).not.toBeVisible();
  await expect(page.getByTestId("coin-count")).toHaveText("160");
  await expect(
    page.getByRole("heading", { name: "Pfirsich", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Pfirsich auswählen" }),
  ).toBeVisible();
  await page.reload();
  await expect(
    page.getByRole("button", { name: "Pfirsich auswählen" }),
  ).toHaveAttribute("aria-pressed", "true");
});

test("clicking a pet in the room selects it and gives it affection", async ({
  page,
}) => {
  await page
    .getByRole("button", { name: "Milo streicheln", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Milo", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Milo auswählen" }),
  ).toHaveAttribute("aria-pressed", "true");
  await expect(
    page.getByRole("progressbar", { name: "Glücklich" }),
  ).toHaveAttribute("aria-valuenow", "66");
});

test("furniture can be bought, moved by keyboard, stored and restored", async ({
  page,
}) => {
  await page.getByRole("button", { name: "Laden", exact: true }).click();
  await page.getByRole("button", { name: "Einrichtung", exact: true }).click();
  await page
    .getByRole("button", { name: "Leselämpchen kaufen für 55 Münzen" })
    .click();
  await expect(page.getByTestId("coin-count")).toHaveText("225");
  const lamp = page.getByRole("button", { name: "Leselämpchen verschieben" });
  await lamp.scrollIntoViewIfNeeded();
  const box = await lamp.boundingBox();
  await page.mouse.move(box!.x + box!.width / 2, box!.y + box!.height / 2);
  await page.mouse.down();
  await page.mouse.move(
    box!.x + box!.width / 2 + 20,
    box!.y + box!.height / 2 + 10,
    { steps: 5 },
  );
  await page.mouse.up();
  let saved = await page.evaluate(
    (key) => JSON.parse(localStorage.getItem(key)!),
    SAVE,
  );
  expect(saved.furniture.at(-1).x).toBeGreaterThan(50);
  const draggedX = saved.furniture.at(-1).x;
  const draggedY = saved.furniture.at(-1).y;
  await lamp.focus();
  await page.keyboard.press("ArrowLeft");
  await page.keyboard.press("ArrowDown");
  saved = await page.evaluate(
    (key) => JSON.parse(localStorage.getItem(key)!),
    SAVE,
  );
  expect(saved.furniture.at(-1).x).toBeCloseTo(draggedX - 2);
  expect(saved.furniture.at(-1).y).toBeCloseTo(draggedY + 2);
  await page.getByRole("button", { name: "Möbel einlagern" }).click();
  await page.getByRole("button", { name: "Möbellager", exact: true }).click();
  await page.getByRole("button", { name: "Aufstellen", exact: true }).click();
  await expect(lamp).toBeVisible();
  await page
    .getByRole("button", { name: "Fertig", exact: true })
    .first()
    .click();
  await page.reload();
  saved = await page.evaluate(
    (key) => JSON.parse(localStorage.getItem(key)!),
    SAVE,
  );
  expect(saved.furniture.at(-1).placed).toBe(true);
  await expect(
    page.getByRole("button", { name: "Einrichten", exact: true }),
  ).toBeVisible();
});

test("exported saves can be imported without losing pets or progress", async ({
  page,
}) => {
  await page.getByRole("button", { name: "Hilfe & Spielstand" }).click();
  const downloadPromise = page.waitForEvent("download");
  await page
    .getByRole("button", { name: "Spielstand exportieren", exact: true })
    .click();
  const download = await downloadPromise;
  const contents = await readFile((await download.path())!, "utf8");
  const exported = JSON.parse(contents);
  expect(exported.pets.map((p: { name: string }) => p.name)).toEqual([
    "Momo",
    "Milo",
  ]);
  exported.pets[0].name = "Sicherung";
  exported.coins = 456;
  page.once("dialog", (dialog) => dialog.accept());
  await page
    .getByLabel("Spielstand importieren", { exact: true })
    .setInputFiles({
      name: "save.json",
      mimeType: "application/json",
      buffer: Buffer.from(JSON.stringify(exported)),
    });
  await expect(
    page.getByRole("heading", { name: "Sicherung", exact: true }),
  ).toBeVisible();
  await expect(page.getByTestId("coin-count")).toHaveText("456");
  const backup = await page.evaluate(
    (key) => JSON.parse(localStorage.getItem(`${key}.backup`)!),
    SAVE,
  );
  expect(backup.pets[0].name).toBe("Momo");
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Sicherung", exact: true }),
  ).toBeVisible();
});

test("daily gift is claimable once and the page fits the viewport", async ({
  page,
}) => {
  await page.getByRole("button", { name: /Dein tägliches Geschenk/ }).click();
  await expect(page.getByTestId("coin-count")).toHaveText("355");
  await expect(
    page.getByRole("button", { name: /Geschenk abgeholt/ }),
  ).toBeDisabled();
  await page.reload();
  await expect(page.getByTestId("coin-count")).toHaveText("355");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
  await page.getByRole("button", { name: "Hilfe & Spielstand" }).click();
  await expect(page.getByRole("dialog")).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).not.toBeVisible();
});

test("corrupted saves recover with a backup and invalid imports preserve progress", async ({
  page,
}) => {
  await page.evaluate((key) => localStorage.setItem(key, "{broken"), SAVE);
  await page.reload();
  await expect(
    page.getByRole("status").filter({ hasText: "Eine Sicherung" }),
  ).toBeVisible();
  expect(
    await page.evaluate((key) => localStorage.getItem(`${key}.backup`), SAVE),
  ).toBe("{broken");
  await page.getByRole("button", { name: "Hilfe & Spielstand" }).click();
  await page
    .getByLabel("Spielstand importieren", { exact: true })
    .setInputFiles({
      name: "invalid.json",
      mimeType: "application/json",
      buffer: Buffer.from("{}"),
    });
  await expect(
    page.getByRole("status").filter({ hasText: "keinen gültigen" }),
  ).toBeVisible();
  const game = await page.evaluate(
    (key) => JSON.parse(localStorage.getItem(key)!),
    SAVE,
  );
  expect(game.coins).toBe(280);
});
