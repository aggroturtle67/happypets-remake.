import { chromium } from 'playwright';
import { readFile, readdir, link, unlink } from 'node:fs/promises';
import assert from 'node:assert/strict';

const browser = await chromium.launch({
  executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || '/usr/bin/chromium',
  headless: true,
  args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'],
});
const context = await browser.newContext({ viewport: { width: 1280, height: 860 }, acceptDownloads: true });
const page = await context.newPage();
const errors = [];
const temporaryAssets = [];
page.on('pageerror', error => errors.push(String(error)));
page.on('console', message => {
  if (message.type() === 'error' && /SCRIPT ERROR|^ERROR:|failed|abort/i.test(message.text())) errors.push(message.text());
});
const base = process.env.PFOTENSTUBE_WEB_URL || 'http://127.0.0.1:8063/';

async function openGame() {
  await page.goto(base);
  await page.waitForSelector('html[data-game-ready="true"]', { timeout: 60000 });
  await page.waitForTimeout(1000);
}

async function exportSave() {
  const event = page.waitForEvent('download');
  await page.mouse.click(403, 636);
  const download = await event;
  assert.equal(download.suggestedFilename(), 'pfotenstube-spielstand.json');
  const path = '/tmp/pfotenstube-browser-test-save.json';
  await download.saveAs(path);
  return JSON.parse(await readFile(path, 'utf8'));
}

async function openHelp() {
  await page.mouse.click(1225, 44);
  await page.waitForTimeout(300);
}

try {
  await openGame();
  assert.equal(await page.evaluate(() => crossOriginIsolated), false, 'Browser game must work without special cross-origin headers');
  await page.screenshot({ path: '/tmp/pfotenstube-browser.png' });
  await openHelp();
  await page.screenshot({ path: '/tmp/pfotenstube-browser-help.png' });
  assert.deepEqual(errors, [], 'Browser runtime must not report script errors');
  console.log('WEB START CHECK PASSED: real Godot WebAssembly runs and opens Help without special hosting headers');
  if (process.env.PFOTENSTUBE_WEB_SMOKE_ONLY !== '1') {
    const fresh = await exportSave();
    assert.equal(fresh.coins, 280);
    await page.mouse.click(954, 169);
    await page.mouse.click(999, 539);
    await page.waitForTimeout(600);
    await openHelp();
    const fed = await exportSave();
    assert.equal(fed.coins, 272, 'Native Feed action must run inside the browser');
    assert(fed.pets[0].hunger > 96);
    await page.reload();
    await page.waitForSelector('html[data-game-ready="true"]', { timeout: 60000 });
    await page.waitForTimeout(1000);
    await openHelp();
    assert.equal((await exportSave()).coins, 272, 'IndexedDB must preserve progress after a reload');

    // Serve the same game under different asset names, as a real update does.
    const shell = await (await page.request.get(base)).text();
    const originalName = shell.match(/executable":"([^"]+)"/)[1];
    const newName = 'pfotenstube-update-' + Date.now();
    const directory = new URL('../godot/builds/web/', import.meta.url);
    for (const filename of await readdir(directory)) {
      if (!filename.startsWith(originalName + '.')) continue;
      const alias = new URL(filename.replace(originalName, newName), directory);
      await link(new URL(filename, directory), alias);
      temporaryAssets.push(alias);
    }
    await page.route('**/update-check.html', route => route.fulfill({
      status: 200,
      contentType: 'text/html',
      body: shell.replaceAll(originalName, newName),
    }));
    await page.goto(new URL('update-check.html', base).href);
    await page.waitForSelector('html[data-game-ready="true"]', { timeout: 60000 });
    await page.waitForTimeout(1000);
    await openHelp();
    assert.equal((await exportSave()).coins, 272, 'Progress must survive an update with new asset names');

    const imported = structuredClone(fed);
    imported.coins = 418;
    imported.pets[0].name = 'Testkatze';
    await page.mouse.click(603, 636);
    await page.locator('dialog input[type=file]').setInputFiles({ name: 'windows-save.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(imported)) });
    await page.waitForTimeout(400);
    await page.screenshot({ path: '/tmp/pfotenstube-browser-import.png' });
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);
    await openHelp();
    const restored = await exportSave();
    assert.equal(restored.coins, 418, 'Import must preserve native Windows save data');
    assert.equal(restored.pets[0].name, 'Testkatze');

    await page.mouse.click(603, 636);
    await page.locator('dialog input[type=file]').setInputFiles({ name: 'broken.json', mimeType: 'application/json', buffer: Buffer.from('{broken') });
    await page.waitForTimeout(300);
    await openHelp();
    assert.equal((await exportSave()).coins, 418, 'Invalid imported files must leave existing progress intact');
    assert.deepEqual(errors, [], 'Gameplay, reload and import must have no runtime errors');
    console.log('WEB SAVE CHECK PASSED: feeding, JSON export/import, invalid-file rejection, reload and asset-update persistence');
  }
} catch (error) {
  await page.screenshot({ path: '/tmp/pfotenstube-browser-failure.png' });
  console.error('Browser diagnostics', errors, await page.evaluate(() => ({
    fileInputs: document.querySelectorAll('input[type=file]').length,
    active: navigator.userActivation.isActive,
    picker: typeof window.pfotenstubeFiles?.chooseSave,
  })));
  throw error;
} finally {
  await browser.close();
  await Promise.all(temporaryAssets.map(path => unlink(path)));
}
