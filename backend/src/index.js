const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const authRoutes = require('./routes/auth');
const syncRoutes = require('./routes/sync');
const uploadRoutes = require('./routes/upload');
const dashboardRoutes = require('./routes/dashboard');

const app = express();
const PORT = process.env.PORT || 3000;
const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '../uploads');
const DASHBOARD_DIR = process.env.DASHBOARD_DIR || (
  fs.existsSync(path.join(__dirname, '../../frontend/web'))
    ? path.join(__dirname, '../../frontend/web')
    : (fs.existsSync(path.join(__dirname, '../../frontend_web'))
        ? path.join(__dirname, '../../frontend_web')
        : path.join(__dirname, '../../../dashboard_pwa'))
);
// Middleware
app.use(cors());
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

// Static files (uploads folder)
app.use('/uploads', express.static(UPLOAD_DIR));

// Serve Web Dashboard PWA (Admin Command Center) if directory exists
if (fs.existsSync(DASHBOARD_DIR)) {
  app.use(express.static(DASHBOARD_DIR));
}

// Healthcheck
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    system: 'TerraPoint Self-Hosted VM Backend',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Fallback for SPA Dashboard routing
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api/') || req.path.startsWith('/uploads/')) {
    return next();
  }
  const indexPath = path.join(DASHBOARD_DIR, 'index.html');
  if (fs.existsSync(indexPath)) {
    return res.sendFile(indexPath);
  }
  res.status(404).send('Not Found');
});

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err);
  res.status(500).json({
    success: false,
    error: err.message || 'Internal Server Error',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`=================================================`);
  console.log(` TerraPoint Backend Server is running!`);
  console.log(` Port: ${PORT}`);
  console.log(` Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(` Upload Directory: ${UPLOAD_DIR}`);
  console.log(` Dashboard Directory: ${DASHBOARD_DIR}`);
  console.log(`=================================================`);
});
