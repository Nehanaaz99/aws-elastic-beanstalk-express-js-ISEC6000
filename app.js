const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

// Hide the "X-Powered-By: Express" header (gives attackers less information)
app.disable('x-powered-by');

app.get('/', (req, res) => res.send('Hello World!'));

// Health check used by the tests and the pipeline
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Only start the server when run directly (node app.js), not when tests load it
if (require.main === module) {
  app.listen(port, () => console.log(`App running on http://localhost:${port}`));
}

module.exports = app;
