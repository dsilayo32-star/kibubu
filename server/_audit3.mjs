export default async function run(page, ui) {
  const out = {};

  // 1. Does pressing Enter in the phone field submit / do nothing? There is no
  //    <form>, so Enter should be inert — confirm no accidental navigation.
  await page.locator('#phone').click();
  await page.keyboard.press('Enter');
  await page.waitForTimeout(400);
  out.urlAfterEnterInPhone = page.url();

  // 2. Enter in the amount field
  await page.locator('#amount').click();
  await page.keyboard.press('Enter');
  await page.waitForTimeout(400);
  out.urlAfterEnterInAmount = page.url();

  // 3. Whitespace-only account reference: the JS trims, server rejects. What
  //    does the UI show? (Should be a clear error, not a fake network error.)
  await page.locator('#amount').fill('1000');
  await page.locator('#phone').fill('255712345678');
  await page.locator('#ref').fill('   ');
  await page.locator('button', { hasText: 'Tuma STK Push' }).click();
  await page.waitForFunction(
    () => !document.getElementById('status').innerText.includes('Inatuma ombi'),
    null, { timeout: 20000 }
  ).catch(() => { });
  out.blankRefStatus = (await page.locator('#status').innerText()).trim();
  out.blankRefLog = (await page.locator('#log').innerText()).trim().slice(0, 100);

  // 4. Invalid phone (server 400) must show the real message, not "Network Error"
  await page.locator('#ref').fill('KIBUBU_TEST');
  await page.locator('#phone').fill('123');
  await page.locator('button', { hasText: 'Tuma STK Push' }).click();
  await page.waitForFunction(
    () => !document.getElementById('status').innerText.includes('Inatuma ombi'),
    null, { timeout: 20000 }
  ).catch(() => { });
  out.badPhoneStatus = (await page.locator('#status').innerText()).trim();
  out.badPhoneLog = (await page.locator('#log').innerText()).trim().slice(0, 120);

  return out;
}
