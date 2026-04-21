const http = require('https');

function testSend(model, toolConfig) {
  const data = JSON.stringify({
    contents: [{ role: 'user', parts: [{ text: 'сколько стоит грант' }] }],
    tools: [toolConfig]
  });

  const req = http.request(
    'https://generativelanguage.googleapis.com/v1beta/models/' + model + ':generateContent?key=AIzaSyAI5nhr9xGwrk4wVyEpgiPXZ4PtOrVVjkU',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    },
    (res) => {
      let result = '';
      res.on('data', (d) => { result += d; });
      res.on('end', () => {
        console.log(model + ' STATUS:', res.statusCode);
        console.log(result.substring(0, 150));
      });
    }
  );
  req.write(data);
  req.end();
}

testSend('gemini-2.0-flash', { googleSearch: {} });
testSend('gemini-2.5-flash', { googleSearch: {} });
