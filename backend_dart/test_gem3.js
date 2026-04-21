const http = require('https');

const data = JSON.stringify({
  contents: [{ role: 'user', parts: [{ text: 'сколько стоит грант' }] }]
});

const req = http.request(
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=AIzaSyAI5nhr9xGwrk4wVyEpgiPXZ4PtOrVVjkU',
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  },
  (res) => {
    let result = '';
    res.on('data', (d) => { result += d; });
    res.on('end', () => {
      console.log('STATUS:', res.statusCode);
      console.log('RESULT:', result.substring(0, 300));
    });
  }
);
req.write(data);
req.end();
