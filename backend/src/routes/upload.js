const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();
const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '../../uploads');

// Pastikan subdirektori evidences ada
const evidencesDir = path.join(UPLOAD_DIR, 'evidences');
if (!fs.existsSync(evidencesDir)) {
  fs.mkdirSync(evidencesDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, evidencesDir);
  },
  filename: (req, file, cb) => {
    const taskId = req.body.task_id || req.query.task_id || 'unknown';
    const type = req.body.checkpoint_type || req.query.checkpoint_type || 'evidence';
    const timestamp = Date.now();
    const ext = path.extname(file.originalname) || '.webp';
    cb(null, `${taskId}_${type}_${timestamp}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedMime = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowedMime.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Format file tidak diizinkan. Hanya JPEG, PNG, dan WebP yang diperbolehkan.'));
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 15 * 1024 * 1024 }, // Max 15 MB
});

/**
 * POST /api/upload/evidence
 * Endpoint penerimaan upload foto bukti berstempel watermark
 */
router.post('/evidence', upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'File foto tidak ditemukan dalam request.' });
    }

    const relativeUrl = `/uploads/evidences/${req.file.filename}`;
    const baseUrl = process.env.BASE_URL || 'http://localhost';
    const fullUrl = `${baseUrl}${relativeUrl}`;

    res.json({
      success: true,
      file_name: req.file.filename,
      relative_url: relativeUrl,
      storage_url: fullUrl,
      file_size_bytes: req.file.size,
    });
  } catch (err) {
    console.error('Evidence upload error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
