var http = require('http');
 
var userString = "Hello World JavaScript";
 
var headers = {
  'Content-Type': 'text/plain',
  'Content-Length': userString.length
};
 
var options = {
  host: 'localhost',
  port: 8080,
  path: '/TOPIC/x',
  method: 'POST',
  headers: headers
};
 
 
// Setup the request.  The options parameter is
// the object we defined above.
var req = http.request(options, function(res) {
  console.log('STATUS: ' + res.statusCode);
  console.log('HEADERS: ' + JSON.stringify(res.headers));
  res.setEncoding('utf8');
  res.on('data', function (chunk) {
    console.log('BODY: ' + chunk);
  });
});
 
req.on('error', function(e) {
  console.log('problem with request: ' + e.message);
});
 
req.write(userString);
req.end();