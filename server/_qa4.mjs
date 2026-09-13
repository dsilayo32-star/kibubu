export default async function run(page, ui) {
  const out = {};

  // Show the ORIGINAL problem: the dashboard's own logic, run against an HTML
  // error body, throws. Reproduce the old code path verbatim.
  out.oldCodePathOnHtmlBody = await page.evaluate(async () => {
    const res = await fetch('/no-such-route'); // returns HTML 404
    try {
      await res.json(); // exactly what the old checkHealth()/sendStkPush() did
      return 'no throw (unexpected)';
    } catch (e) {
      return 'THREW: ' + e.message;
    }
  });

  // Verify the NEW UI surfaces a real message: intercept fetch so /api/v1/stkpush
  // returns an HTML error, then click and read the status pill.
  await page.route('**/api/v1/stkpush', (route) =>
    route.fulfill({
      status: 404,
      contentType: 'text/html; charset=utf-8',
      body: '<html><body><pre>Cannot POST /api/v1/stkpush</pre></body></html>',
    })
  );

  await page.locator('#amount').fill('1000');
  await page.locator('button', { hasText: 'Tuma STK Push' }).click();
  await page.waitForFunction(
    () => !document.getElementById('status').innerText.includes('Inatuma ombi'),
    null,
    { timeout: 15000 }
  ).catch(() => { });

  out.newUiStatus = (await page.locator('#status').innerText()).trim();
  out.newUiLog = (await page.locator('#log').innerText()).trim();

  return out;
}
