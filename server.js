const express = require('express');
const path = require('path');
const app = express();
const PORT = 5000;

// Serve static files (images, json, etc.)
app.use(express.static(path.join(__dirname, 'build')));

// Serve index.html for root and any unknown route (for SPA or static HTML)
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

// Serve index.html for all other routes (for SPA or static HTML)
app.use((req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});