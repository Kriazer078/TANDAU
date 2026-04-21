const http = require('https');

const req = http.request(
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyDWfTtrWhWDz2MtQOs-sMquVPJdoeZVkFo',
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  },
  (res) => {
    let result = '';
    res.on('data', (d) => { result += d; });
    res.on('end', () => {
      console.log('STATUS:', res.statusCode);
      console.log('RESULT:', result.substring(0, 500));
    });
  }
);
req.write(JSON.stringify({ contents: [{ role: 'user', parts: [{ text: 'hi' }] }] }));
req.end();
