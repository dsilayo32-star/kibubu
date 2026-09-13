'use strict';

/*
 * test-stk.js — Jaribu STK Push kwa namba ya Tanzania kupitia server yako ya ndani.
 *
 * Matumizi (PowerShell):
 *   1. Katika terminal moja:  npm start        (inaanzisha server kwenye PORT kutoka .env)
 *   2. Katika terminal nyingine: node test-stk.js <NAMBA> [KIASI]
 *
 * Mfano:
 *   node test-stk.js 0754123456 1000
 *
 * Namba ya Tanzania pekee inakubaliwa. Server huituma kwa Daraja kama
 * 255XXXXXXXXX (hakuna kubadilisha kwenda namba ya Kenya).
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '..', '.env') });
const axios = require('axios');

const [, , phoneArg, amountArg] = process.argv;

if (!phoneArg) {
  console.error('Matumizi: node test-stk.js <NAMBA_YA_TANZANIA> [KIASI]');
  console.error('Mfano:   node test-stk.js 0754123456 1000');
  process.exit(1);
}

const PORT = process.env.PORT || 5000;
const amount = Number(amountArg || 1000);
const baseUrl = `http://localhost:${PORT}`;

(async () => {
  console.log(`Inatuma STK Push -> ${baseUrl}/api/v1/stkpush`);
  console.log(`  phoneNumber = ${phoneArg}`);
  console.log(`  amount      = ${amount}`);
  console.log(`  env         = ${process.env.MPESA_ENV || 'sandbox'}`);
  console.log('');

  try {
    const res = await axios.post(`${baseUrl}/api/v1/stkpush`, {
      phoneNumber: phoneArg,
      amount,
      accountReference: 'KIBUBU_TEST',
    });
    console.log('✅ MAFANIKIO. Jibu la Daraja:');
    console.log(JSON.stringify(res.data, null, 2));
    console.log('\nAngalia simu yako kwa USSD/PIN prompt ya M-Pesa.');
  } catch (err) {
    const status = err.response?.status;
    const data = err.response?.data;
    console.log('❌ IMEFELI.');
    if (status) console.log(`HTTP ${status}`);
    console.log(JSON.stringify(data || err.message, null, 2));

    if (status === 400 && JSON.stringify(data).includes('OAuth')) {
      console.log('\nKidokezo: Credentials za Daraja si sahihi au zimepitwa na muda.');
      console.log('Weka mpya:  node set-credentials.js <KEY> <SECRET>');
    }
  }
})();
