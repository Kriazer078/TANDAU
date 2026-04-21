const http = require('https');

function testSend(toolConfig, label) {
  const data = JSON.stringify({
    contents: [{ role: 'user', parts: [{ text: 'сколько стоит грант' }] }],
    tools: [toolConfig]
  });

  const req = http.request(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=invalid_key_12345',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    },
    (res) => {
      let result = '';
      res.on('data', (d) => { result += d; });
      res.on('end', () => {
        console.log(label + ' STATUS:', res.statusCode);
        console.log(result.substring(0, 150));
      });
    }
  );
  req.write(data);
  req.end();
}

// testSend({ googleSearch: {} }, 'googleSearch');
testSend({ google_search: {} }, 'google_search');
testSend({ googleSearchRetrieval: { dynamicRetrievalConfig: { mode: 'MODE_DYNAMIC', dynamicThreshold: 0.3 } } }, 'googleSearchRetrieval');

