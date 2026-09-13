function normalizePhone(phoneNumber) {
  // Namba za Tanzania pekee zinaruhusiwa: 0XXXXXXXXX / 255XXXXXXXXX / +255XXXXXXXXX.
  const value = String(phoneNumber ?? '').replace(/[\s-]/g, '');
  if (/^07\d{8}$/.test(value)) return `255${value.slice(1)}`;
  if (/^2557\d{8}$/.test(value)) return value;
  if (/^\+2557\d{8}$/.test(value)) return value.slice(1);
  return null;
}

function resolveDarajaPhoneNumber(normalizedPhone) {
  // Namba za Tanzania zinatumwa kwa Daraja kama zilivyo (255XXXXXXXXX).
  // Hatubadilishi kwenda namba ya majaribio ya Kenya.
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
  resolveDarajaPhoneNumber,
  positiveAmount,
  safeReference,
};
