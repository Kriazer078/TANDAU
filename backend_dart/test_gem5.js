const http = require('https');

const req = http.request(
  'https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyAI5nhr9xGwrk4wVyEpgiPXZ4PtOrVVjkU',
  { method: 'GET' },
  (res) => {
    let result = '';
    res.on('data', (d) => { result += d; });
    res.on('end', () => {
      const json = JSON.parse(result);
      console.log('NAMES:', json.models.map(m => m.name));
    });
  }
);
req.end();
