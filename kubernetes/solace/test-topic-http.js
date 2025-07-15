const http = require('http');

const NUM_MESSAGES = 2;
const DELAY_MS = 200;
const host = 'localhost';
const port = 9000;
const path = '/QUEUE';
const topic = 'my/topic/http';
const username = 'test';
const password = 'test';

// Codificamos "test:test" en base64 para usar en el header Authorization
const auth = Buffer.from(`${username}:${password}`).toString('base64');

function sendMessage(index) {
  const userString = `Mensaje ${index + 1}`;

  const headers = {
    'Content-Type': 'text/plain',
    'Content-Length': Buffer.byteLength(userString),
   // 'Solace-DMQ-Eligible': true,
    'Solace-Topic': topic,
    'Authorization': `Basic ${auth}`
  };

  const options = {
    host: host,
    port: port,
    path: path,
    method: 'POST',
    headers: headers
  };

  const req = http.request(options, function (res) {
    console.log(`→ Mensaje ${index + 1} enviado`);
    console.log(`STATUS: ${res.statusCode}`);
    console.log(`HEADERS: ${JSON.stringify(res.headers)}`);

    let responseBody = '';
    res.setEncoding('utf8');
    res.on('data', function (chunk) {
      responseBody += chunk;
    });

    res.on('end', function () {
      console.log(`BODY:\n${responseBody}`);
    });
  });

req.on('error', function (e) {
  console.error(`❌ Error en mensaje ${index + 1}: ${e.message}`);
  if (e.errors) {
    e.errors.forEach((subErr, i) => {
      console.error(`  ↳ Suberror ${i + 1}: ${subErr.message}`);
    });
  } else {
    console.error(e);
  }
});

  req.write(userString);
  req.end();

  if (index + 1 < NUM_MESSAGES) {
    setTimeout(() => sendMessage(index + 1), DELAY_MS);
  }
}

sendMessage(0);