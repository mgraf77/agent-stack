// Minimal browser smoke-check skeleton. Fill in the constants below and
// point PLAYWRIGHT_CHROMIUM_PATH at a local Chromium binary if the default
// download is unavailable (e.g. it's pre-installed at a fixed path).
//
// Run with: node smoke.spec.template.js
'use strict';

const BASE_URL = process.env.SMOKE_BASE_URL || 'http://localhost:3000';
const GOLDEN_PATH_SELECTOR = 'body'; // replace with the real element to assert on
const CHROMIUM_PATH = process.env.PLAYWRIGHT_CHROMIUM_PATH || undefined;

async function main() {
  const { chromium } = require('playwright');

  const browser = await chromium.launch({
    executablePath: CHROMIUM_PATH,
  });

  const page = await browser.newPage();
  const consoleErrors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });

  await page.goto(BASE_URL);
  await page.waitForSelector(GOLDEN_PATH_SELECTOR);

  // TODO: exercise the golden path here, e.g.:
  // await page.click('text=Submit');
  // await page.waitForSelector('text=Success');

  await page.screenshot({ path: 'smoke-check.png' });

  if (consoleErrors.length > 0) {
    console.error('console errors detected:', consoleErrors);
    process.exitCode = 1;
  } else {
    console.log('smoke check OK, screenshot saved to smoke-check.png');
  }

  await browser.close();
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
