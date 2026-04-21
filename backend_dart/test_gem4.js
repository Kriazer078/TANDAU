const http = require('https');

const req = http.request(
  'https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyAI5nhr9xGwrk4wVyEpgiPXZ4PtOrVVjkU',
  { method: 'GET' },
  (res) => {
    let result = '';
    res.on('data', (d) => { result += d; });
    res.on('end', () => {
      console.log('STATUS:', res.statusCode);
      console.log('RESULT:', result.substring(0, 500));
    });
  }
);
req.end();
