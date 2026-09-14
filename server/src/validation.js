function normalizePhone(phoneNumber) {
  // Inaruhusu namba za Tanzania (255) na Kenya (254).
  // 12 digits total: 254XXXXXXXXX na 255XXXXXXXXX
  const value = String(phoneNumber ?? '').replace(/[\s-]/g, '');

  // Tanzania: 07XXXXXXXX au 06XXXXXXXX -> 255XXXXXXXXX (12 digits)
  if (/^0[67]\d{8}$/.test(value)) return `255${value.slice(1)}`;
  if (/^255[67]\d{8}$/.test(value)) return value;
  if (/^\+255[67]\d{8}$/.test(value)) return value.slice(1);

  // Kenya: 07XXXXXXXX au 01XXXXXXXX -> 254XXXXXXXXX (12 digits)
  if (/^0[17]\d{8}$/.test(value)) return `254${value.slice(1)}`;
  // Kenya: 254XXXXXXXXX (12 digits total: 254 followed by 9 digits)
  if (/^254[17]\d{8}$/.test(value)) return value;
  if (/^\+254[17]\d{8}$/.test(value)) return value.slice(1);
  // General Kenyan 12-digit format support:
  if (/^254\d{9}$/.test(value)) return value;
  if (/^\+254\d{9}$/.test(value)) return value.slice(1);

  return null;
}

/**
 * Detects the country code from normalized 12-digit phone number.
 * @param {string} normalizedPhone
 * @returns {'254'|'255'|null}
 */
function detectCountryCode(normalizedPhone) {
  if (!normalizedPhone || typeof normalizedPhone !== 'string') return null;
  if (normalizedPhone.startsWith('254')) return '254';
  if (normalizedPhone.startsWith('255')) return '255';
  return null;
}

function resolveDarajaPhoneNumber(normalizedPhone) {
  return normalizedPhone || null;
}

// Kiwango cha juu cha kuweka akiba kinacholingana na app ya Kibubu (TSh 1,000,000).
const MAX_AMOUNT = 1000000;

function positiveAmount(value) {
  const amount = Number(value);
  return Number.isInteger(amount) && amount > 0 && amount <= MAX_AMOUNT;
}

function safeReference(value) {
  const reference = String(value ?? '').trim();
  return /^[A-Za-z0-9_-]{1,40}$/.test(reference) ? reference : null;
}

module.exports = {
  MAX_AMOUNT,
  normalizePhone,
  detectCountryCode,
  resolveDarajaPhoneNumber,
  positiveAmount,
  safeReference,
};
