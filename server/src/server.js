require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const path = require('path');
const express = require('express');
const cors = require('cors');
const { router } = require('./routes');
const { getFirestore } = require('./firebase');
const {
  normalizePhone,
  resolveDarajaPhoneNumber,
  DEFAULT_SANDBOX_PHONE,
  positiveAmount,
  safeReference,
} = require('./validation');

// --- Composition root -------------------------------------------------------
// server.js only wires middleware, static assets and the API router together.
// Business logic lives in config/ daraja/ orders/ routes/.

const app = express();
app.use(cors());
app.options('*', cors());
app.use(express.json({ limit: '32kb' }));

app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'Kibubu M-Pesa API',
    message: 'Kibubu Backend API is running',
    endpoints: {
      health: '/health',
      status: '/api/status',
      stkPush: '/api/v1/stkpush',
      callback: '/api/v1/mpesa-callback',
      testDashboard: '/dashboard',
    },
  });
});

app.get(['/dashboard', '/test'], (_req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.use(express.static(path.join(__dirname, '../public'), { index: false }));

// All API routes live in ./routes.
app.use(router);

// JSON error handler, registered last so it catches anything the router or
// express.json() throws. Without it Express falls back to its HTML error page,
// and API clients that call res.json() choke on "<!DOCTYPE ..." instead of
// reading the error. The 4 arguments are what marks this as an error handler.
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  const status = err.status || err.statusCode || 500;

  if (err.type === 'entity.parse.failed' || err instanceof SyntaxError) {
    return res.status(400).json({ error: 'Request body must be valid JSON.' });
  }
  if (err.type === 'entity.too.large') {
    return res.status(413).json({ error: 'Request body is too large.' });
  }

  console.error('[Server Error]', err.message);
  return res.status(status).json({ error: err.message || 'Internal server error.' });
});

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  app.listen(port, () => console.log(`Server running on port ${port}`));
}

module.exports = {
  app,
  getFirestore,
  normalizePhone,
  resolveDarajaPhoneNumber,
  DEFAULT_SANDBOX_PHONE,
  positiveAmount,
  safeReference,
};
