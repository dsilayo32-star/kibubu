export default async function run(page, ui) {
  const out = {};
  const status = async () => (await page.locator('#status').innerText()).trim();
  const log = async () => (await page.locator('#log').innerText()).trim();

  // 1. Health
  await page.locator('button', { hasText: 'Check Health' }).click();
  await page.waitForTimeout(800);
  out.health = await status();

  // 2. Blank amount -> client-side guard
  await page.locator('#amount').fill('');
  await page.locator('button', { hasText: 'Tuma STK Push' }).click();
  await page.waitForTimeout(600);
  out.blankAmount = await status();

  // 3. Over ceiling
  await page.locator('#amount').fill('250000');
  await page.locator('button', { hasText: 'Tuma STK Push' }).click();
  await page.waitForTimeout(600);
  out.overCeiling = await status();

  // 4. Server 400 with JSON body -> real message, and log should NOT duplicate
  await page.locator('#amount').fill('1000');
  await page.locator('#phone').fill('123');
  await page.locator('#ref').fill('KIBUBU_TEST');
  await page.locator('button', { hasText: 'Tuma STK Push' }).click();
  await page.waitForFunction(
    () => !document.getElementById('status').innerText.includes('Inatuma ombi'),
    null, { timeout: 20000 }
  ).catch(() => { });
  out.badPhoneStatus = await status();
  out.badPhoneLog = await log();
  out.badPhoneLogOccurrences = (await log()).split('phoneNumber must be').length - 1;

  // 5. HTML error body path still handled (no fake Network Error)
  await page.route('**/api/v1/stkpush', (route) =>
    route.fulfill({
      status: 502,
      contentType: 'text/html',
      body: '<html><body><h1>502 Bad Gateway</h1></body></html>',
    })
  );
  await page.locator('#phone').fill('255712345678');
  await page.locator('button', { hasText: 'Tuma STK Push' }).click();
  await page.waitForFunction(
    () => !document.getElementById('status').innerText.includes('Inatuma ombi'),
    null, { timeout: 20000 }
  ).catch(() => { });
  out.htmlErrorStatus = await status();
  out.htmlErrorLog = await log();

  // 6. Accessibility wiring added in this pass
  out.a11y = await page.evaluate(() => ({
    statusRole: document.getElementById('status').getAttribute('role'),
    statusLive: document.getElementById('status').getAttribute('aria-live'),
    phoneDescribedBy: document.getElementById('phone').getAttribute('aria-describedby'),
    hintExists: !!document.getElementById('phone-hint'),
  }));

  return out;
}
