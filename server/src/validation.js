function normalizePhone(phoneNumber, allowSandboxKenya = false) {
  const value = String(phoneNumber ?? '').replace(/[\s-]/g, '');
  if (/^07\d{8}$/.test(value)) return `255${value.slice(1)}`;
  if (/^2557\d{8}$/.test(value)) return value;
  if (/^\+2557\d{8}$/.test(value)) return value.slice(1);
  if (allowSandboxKenya) {
    if (/^2547\d{8}$/.test(value)) return value;
    if (/^\+2547\d{8}$/.test(value)) return value.slice(1);
    if (/^01\d{8}$/.test(value)) return `254${value.slice(1)}`;
  }
  return null;
}

const DEFAULT_SANDBOX_PHONE = '254708374149';

function resolveDarajaPhoneNumber(normalizedPhone, isSandbox = false) {
  if (!normalizedPhone) return null;
  if (isSandbox) {
    if (normalizedPhone.startsWith('255')) {
      return DEFAULT_SANDBOX_PHONE;
    }
    return normalizedPhone;
  }
  return normalizedPhone;
}

function positiveAmount(value) {
  const amount = Number(value);
  return Number.isInteger(amount) && amount > 0 && amount <= 150000;
}

function safeReference(value) {
  const reference = String(value ?? '').trim();
  return /^[A-Za-z0-9_-]{1,40}$/.test(reference) ? reference : null;
}

module.exports = {
  normalizePhone,
  resolveDarajaPhoneNumber,
  DEFAULT_SANDBOX_PHONE,
  positiveAmount,
  safeReference,
};
