require('dotenv').config({ path: 'server/.env' });
const { app } = require('./src/server');

const server = app.listen(5055, async () => {
  console.log('Local test server running on 5055');
  const axios = require('axios');
  try {
    const rootRes = await axios.get('http://localhost:5055/');
    console.log('GET / response:', rootRes.data);

    const statusRes = await axios.get('http://localhost:5055/api/status');
    console.log('GET /api/status response:', statusRes.data);

    const healthRes = await axios.get('http://localhost:5055/health');
    console.log('GET /health response:', healthRes.data);

    const valRes = await axios.post('http://localhost:5055/api/v1/stkpush', {
      phoneNumber: 'invalid'
    }).catch(err => err.response);
    console.log('POST /api/v1/stkpush validation status:', valRes.status, valRes.data);

  } catch (e) {
    console.error('Test error:', e);
  } finally {
    server.close(() => console.log('Local test server stopped'));
  }
});
