'use strict';

/*
 * set-credentials.js — Weka credentials za Daraja kwenye server/.env kwa haraka.
 *
 * Matumizi (PowerShell):
 *   node set-credentials.js <CONSUMER_KEY> <CONSUMER_SECRET> [SHORTCODE] [PASSKEY]
 *
 * Mfano:
 *   node set-credentials.js AbC123... XyZ456... 174379 bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
 *
 * Kisha jaribu:
 *   node test-stk.js 0754123456 1000
 */

const fs = require('fs');
const path = require('path');

const ENV_PATH = path.resolve(__dirname, '..', '.env');

const [, , key, secret, shortcode, passkey] = process.argv;

if (!key || !secret) {
  console.error('Matumizi: node set-credentials.js <CONSUMER_KEY> <CONSUMER_SECRET> [SHORTCODE] [PASSKEY]');
  process.exit(1);
}

let env = fs.existsSync(ENV_PATH) ? fs.readFileSync(ENV_PATH, 'utf8') : '';

function setVar(source, name, value) {
  const line = `${name}=${value}`;
  const re = new RegExp(`^${name}=.*$`, 'm');
  if (re.test(source)) return source.replace(re, line);
  return `${source.replace(/\s*$/, '')}\n${line}\n`;
}

env = setVar(env, 'DARAJA_CONSUMER_KEY', key);
env = setVar(env, 'DARAJA_CONSUMER_SECRET', secret);
if (shortcode) env = setVar(env, 'MPESA_SHORTCODE', shortcode);
if (passkey) env = setVar(env, 'MPESA_PASSKEY', passkey);

fs.writeFileSync(ENV_PATH, env, 'utf8');

// Onyesha muhtasari bila kufichua siri kamili.
const mask = (v) => (v.length <= 6 ? '******' : `${v.slice(0, 4)}...${v.slice(-4)}`);
console.log('Credentials zimehifadhiwa kwenye server/.env:');
console.log(`  DARAJA_CONSUMER_KEY    = ${mask(key)}`);
console.log(`  DARAJA_CONSUMER_SECRET = ${mask(secret)}`);
if (shortcode) console.log(`  MPESA_SHORTCODE        = ${shortcode}`);
if (passkey) console.log(`  MPESA_PASSKEY          = ${mask(passkey)}`);
console.log('\nJaribu sasa:  node test-stk.js 0754123456 1000');
