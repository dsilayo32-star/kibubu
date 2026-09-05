function normalizePhone(phoneNumber) {
  const value = String(phoneNumber ?? '').replace(/[\s-]/g, '');
  if (/^07\d{8}$/.test(value)) return `255${value.slice(1)}`;
  if (/^2557\d{8}$/.test(value)) return value;
  if (/^\+2557\d{8}$/.test(value)) return value.slice(1);
  return null;
}

function positiveAmount(value) {
  const amount = Number(value);
  return Number.isInteger(amount) && amount > 0 && amount <= 150000;
}

function safeReference(value) {
  const reference = String(value ?? '').trim();
  return /^[A-Za-z0-9_-]{1,40}$/.test(reference) ? reference : null;
}

module.exports = { normalizePhone, positiveAmount, safeReference };
