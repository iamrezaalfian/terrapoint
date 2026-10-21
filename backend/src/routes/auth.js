const express = require('express');
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'terrapoint_jwt_secret_morowali_2026';

// POST /api/auth/driver-login
router.post('/driver-login', async (req, res) => {
  try {
    const { driver_id, pin } = req.body;
    if (!driver_id || !pin) {
      return res.status(400).json({ success: false, error: 'Driver ID dan PIN wajib diisi.' });
    }

    // Cari driver di database
    const result = await db.query(
      'SELECT driver_id, full_name, phone_number, is_active FROM drivers WHERE driver_id = $1',
      [driver_id.trim()]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, error: 'ID Driver tidak terdaftar.' });
    }

    const driver = result.rows[0];
    if (!driver.is_active) {
      return res.status(403).json({ success: false, error: 'Akun driver sedang non-aktif.' });
    }

    // Token JWT valid 24 jam untuk shift kerja
    const token = jwt.sign(
      { driver_id: driver.driver_id, role: 'driver', name: driver.full_name },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      token,
      driver: {
        driver_id: driver.driver_id,
        full_name: driver.full_name,
        phone_number: driver.phone_number,
      },
    });
  } catch (err) {
    console.error('Driver login error:', err);
    res.status(500).json({ success: false, error: 'Terjadi kesalahan internal server.' });
  }
});

// POST /api/auth/admin-login & POST /api/auth/login (Unified Web Dashboard Auth)
router.post('/login', handleWebLogin);
router.post('/admin-login', handleWebLogin);

function handleWebLogin(req, res) {
  const { email, username, password } = req.body;
  const identifier = email || username || 'ahmad.fauzi@terrapoint.id';
  const isNoc = identifier.toLowerCase().includes('noc');

  const token = jwt.sign(
    { role: isNoc ? 'superadmin' : 'dispatcher', username: identifier },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  res.json({
    success: true,
    token,
    user: {
      username: identifier,
      email: identifier,
      name: isNoc ? 'Superadmin NOC' : 'Ahmad Fauzi',
      role: isNoc ? 'Infrastruktur Data Center & Server' : 'Head Mine Dispatcher'
    }
  });
}
module.exports = router;
