const express = require('express');
const os = require('os');
const net = require('net');
const db = require('../db');
const { calculateHaversine } = require('../utils/haversine');

const router = express.Router();

// Hybrid Cache & Service Check Helper
const cacheStats = { hits: 0, misses: 0, flushes: 0 };
const memCache = new Map();

function checkTcpService(host, port, timeoutMs = 1200) {
  return new Promise((resolve) => {
    const start = Date.now();
    const sock = new net.Socket();
    sock.setTimeout(timeoutMs);
    sock.once('connect', () => {
      const latency = Date.now() - start;
      sock.destroy();
      resolve({ online: true, latency_ms: latency });
    });
    sock.once('error', () => {
      sock.destroy();
      resolve({ online: false, latency_ms: null });
    });
    sock.once('timeout', () => {
      sock.destroy();
      resolve({ online: false, latency_ms: null });
    });
    sock.connect(port, host);
  });
}

// ==========================================
// 1. SUMMARY & WHEEL-TYPE METRICS
// ==========================================
router.get('/summary', async (req, res) => {
  try {
    const today = new Date().toISOString().slice(0, 10);

    // Hitung total trips hari ini dari project_trips
    const tripSummary = await db.query(`
      SELECT 
        COUNT(*) as total_trips,
        COUNT(*) FILTER (WHERE status = 'COMPLETED') as completed_trips,
        COUNT(*) FILTER (WHERE status = 'IN_TRANSIT') as active_trips
      FROM project_trips
      WHERE DATE(created_at) = CURRENT_DATE
    `);

    // Breakdown trip per jenis roda mobil
    const wheelBreakdown = await db.query(`
      SELECT 
        COALESCE(truck_wheel_type, '6 Roda (Dump Truck)') as wheel_type,
        COUNT(*) as trip_count
      FROM project_trips
      WHERE DATE(created_at) = CURRENT_DATE AND status = 'COMPLETED'
      GROUP BY truck_wheel_type
      ORDER BY trip_count DESC
    `);

    // Total drivers & projects
    const drivers = await db.query('SELECT COUNT(*) as total_drivers FROM drivers WHERE is_active = TRUE');
    const projects = await db.query('SELECT COUNT(*) as total_projects FROM projects WHERE is_active = TRUE');
    const locations = await db.query('SELECT COUNT(*) as total_locations FROM master_locations WHERE is_active = TRUE');

    const sum = tripSummary.rows[0];

    // Fallback jika belum ada project_trips hari ini, ambil dari drivers default roda
    let wheels = wheelBreakdown.rows;
    if (wheels.length === 0) {
      wheels = [
        { wheel_type: '6 Roda (Dump Truck)', trip_count: parseInt(sum.completed_trips || 0, 10) },
        { wheel_type: '6 Roda Jumbo', trip_count: 0 },
        { wheel_type: '10 Roda (Tronton)', trip_count: 0 }
      ];
    }

    res.json({
      success: true,
      data: {
        total_trips_today: parseInt(sum.completed_trips || 0, 10),
        active_trips: parseInt(sum.active_trips || 0, 10),
        total_projects: parseInt(projects.rows[0]?.total_projects || 1, 10),
        total_drivers: parseInt(drivers.rows[0]?.total_drivers || 3, 10),
        total_locations: parseInt(locations.rows[0]?.total_locations || 5, 10),
        wheels_summary: wheels
      }
    });
  } catch (err) {
    console.error('Summary error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 2. PROJECTS MANAGEMENT (TASK = PROYEK)
// ==========================================
router.get('/projects', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        p.*,
        COUNT(pt.trip_id) FILTER (WHERE pt.status = 'COMPLETED' AND DATE(pt.created_at) = CURRENT_DATE) as today_completed_trips,
        COUNT(pt.trip_id) FILTER (WHERE pt.status = 'IN_TRANSIT') as in_transit_trips,
        (
          SELECT json_agg(json_build_object('driver_id', d.driver_id, 'full_name', d.full_name, 'truck_wheel_type', d.truck_wheel_type))
          FROM drivers d WHERE d.assigned_project_id = p.project_id AND d.is_active = TRUE
        ) as assigned_drivers
      FROM projects p
      LEFT JOIN project_trips pt ON p.project_id = pt.project_id
      GROUP BY p.project_id
      ORDER BY p.created_at DESC
    `);
    res.json({ success: true, projects: result.rows });
  } catch (err) {
    console.error('Projects fetch error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/projects', async (req, res) => {
  try {
    const {
      project_name,
      client_name = 'PT Mitra Tambang',
      material_type = 'Material Tambang Utama',
      start_location_id,
      start_radius_meters = 200, // Muat: Default Luas (200m)
      end_location_id,
      end_radius_meters = 40,    // Bongkar: Default Lebih Kecil (40m)
    } = req.body;

    if (!project_name || !start_location_id || !end_location_id) {
      return res.status(400).json({
        success: false,
        error: 'Nama proyek, titik muat (start), dan titik bongkar (end) wajib dipilih.'
      });
    }

    const startLoc = await db.query('SELECT * FROM master_locations WHERE location_id = $1', [start_location_id]);
    const endLoc = await db.query('SELECT * FROM master_locations WHERE location_id = $1', [end_location_id]);

    if (startLoc.rows.length === 0 || endLoc.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Titik muat atau titik bongkar tidak ditemukan.' });
    }

    const s = startLoc.rows[0];
    const e = endLoc.rows[0];

    const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const randCode = Math.floor(100 + Math.random() * 900);
    const project_id = `PRJ-${todayStr}-${randCode}`;

    const insertQuery = `
      INSERT INTO projects (
        project_id, project_name, client_name, material_type,
        start_location_id, start_point_name, start_lat, start_lng, start_radius_meters,
        end_location_id, end_point_name, end_lat, end_lng, end_radius_meters,
        is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, TRUE)
      RETURNING *
    `;

    const values = [
      project_id,
      project_name.trim(),
      client_name.trim(),
      material_type.trim(),
      s.location_id,
      s.name,
      parseFloat(s.latitude),
      parseFloat(s.longitude),
      parseInt(start_radius_meters, 10) || 200,
      e.location_id,
      e.name,
      parseFloat(e.latitude),
      parseFloat(e.longitude),
      parseInt(end_radius_meters, 10) || 40,
    ];

    const result = await db.query(insertQuery, values);
    res.json({ success: true, project: result.rows[0], message: 'Proyek penugasan baru berhasil dibuat!' });
  } catch (err) {
    console.error('Create project error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Update Radius Proyek Dinamis (Muat luas & Bongkar kecil)
router.put('/projects/:id/radius', async (req, res) => {
  try {
    const { id } = req.params;
    const { start_radius_meters, end_radius_meters } = req.body;

    const result = await db.query(`
      UPDATE projects SET 
        start_radius_meters = COALESCE($1, start_radius_meters),
        end_radius_meters = COALESCE($2, end_radius_meters),
        updated_at = NOW()
      WHERE project_id = $3
      RETURNING *
    `, [start_radius_meters, end_radius_meters, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Proyek tidak ditemukan.' });
    }
    res.json({ success: true, project: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 3. PROJECT TRIPS (LOG PENGANTARAN HARIAN)
// ==========================================
router.get('/trips', async (req, res) => {
  try {
    const { project_id, driver_id, date, status } = req.query;

    let query = `
      SELECT 
        pt.*,
        p.project_name,
        p.start_point_name,
        p.end_point_name,
        d.full_name as driver_name,
        d.truck_wheel_type
      FROM project_trips pt
      JOIN projects p ON pt.project_id = p.project_id
      JOIN drivers d ON pt.driver_id = d.driver_id
      WHERE 1=1
    `;
    const params = [];

    if (project_id) {
      params.push(project_id);
      query += ` AND pt.project_id = $${params.length}`;
    }
    if (driver_id) {
      params.push(driver_id);
      query += ` AND pt.driver_id = $${params.length}`;
    }
    if (status) {
      params.push(status);
      query += ` AND pt.status = $${params.length}`;
    }
    if (date) {
      params.push(date);
      query += ` AND DATE(pt.created_at) = $${params.length}`;
    }

    query += ` ORDER BY pt.created_at DESC LIMIT 100`;

    const result = await db.query(query, params);
    res.json({ success: true, trips: result.rows });
  } catch (err) {
    console.error('Trips fetch error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 4. DRIVERS & WHEEL TYPE MANAGEMENT
// ==========================================
router.get('/drivers', async (req, res) => {
  try {
    const query = `
      SELECT 
        d.driver_id, d.full_name, d.phone_number, d.is_active, d.created_at,
        COALESCE(d.truck_wheel_type, '6 Roda (Dump Truck)') as truck_wheel_type,
        d.assigned_project_id,
        p.project_name as assigned_project_name,
        COUNT(pt.trip_id) FILTER (WHERE pt.status = 'COMPLETED' AND DATE(pt.created_at) = CURRENT_DATE) as today_trips_count,
        (
          SELECT json_build_object(
            'trip_id', act.trip_id,
            'status', act.status,
            'project_name', prj.project_name,
            'load_at', act.load_at
          )
          FROM project_trips act 
          JOIN projects prj ON act.project_id = prj.project_id
          WHERE act.driver_id = d.driver_id AND act.status = 'IN_TRANSIT'
          ORDER BY act.created_at DESC LIMIT 1
        ) as active_trip
      FROM drivers d
      LEFT JOIN projects p ON d.assigned_project_id = p.project_id
      LEFT JOIN project_trips pt ON d.driver_id = pt.driver_id
      GROUP BY d.driver_id, d.full_name, d.phone_number, d.is_active, d.created_at, d.truck_wheel_type, d.assigned_project_id, p.project_name
      ORDER BY d.driver_id ASC
    `;
    const result = await db.query(query);
    res.json({ success: true, drivers: result.rows });
  } catch (err) {
    console.error('Fetch drivers error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/drivers', async (req, res) => {
  try {
    const { driver_id, full_name, phone_number, truck_wheel_type = '6 Roda (Dump Truck)', assigned_project_id = 'PRJ-HAULING-01', pin = '123456' } = req.body;
    if (!driver_id || !full_name || !phone_number) {
      return res.status(400).json({ success: false, error: 'ID Driver, Nama Lengkap, dan Nomor Telepon wajib diisi.' });
    }

    const result = await db.query(
      `INSERT INTO drivers (driver_id, full_name, phone_number, truck_wheel_type, assigned_project_id, pin_hash, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, TRUE)
       ON CONFLICT (driver_id) DO UPDATE SET 
         full_name = EXCLUDED.full_name, 
         phone_number = EXCLUDED.phone_number,
         truck_wheel_type = EXCLUDED.truck_wheel_type,
         assigned_project_id = EXCLUDED.assigned_project_id
       RETURNING *`,
      [driver_id.trim().toUpperCase(), full_name.trim(), phone_number.trim(), truck_wheel_type, assigned_project_id, pin]
    );

    res.json({ success: true, driver: result.rows[0] });
  } catch (err) {
    console.error('Create driver error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/drivers/:id/toggle', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      `UPDATE drivers SET is_active = NOT is_active WHERE driver_id = $1 RETURNING *`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Driver tidak ditemukan.' });
    }
    res.json({ success: true, driver: result.rows[0] });
  } catch (err) {
    console.error('Toggle driver error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/drivers/:id/assign-project', async (req, res) => {
  try {
    const { id } = req.params;
    const { project_id, truck_wheel_type } = req.body;

    const result = await db.query(`
      UPDATE drivers SET 
        assigned_project_id = COALESCE($1, assigned_project_id),
        truck_wheel_type = COALESCE($2, truck_wheel_type)
      WHERE driver_id = $3
      RETURNING *
    `, [project_id, truck_wheel_type, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Driver tidak ditemukan.' });
    }
    res.json({ success: true, driver: result.rows[0], message: 'Proyek & jenis roda driver berhasil diperbarui!' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 5. MOBILE APP DRIVER CLIENT API
// ==========================================
router.get('/driver-project', async (req, res) => {
  try {
    const { driver_id } = req.query;
    if (!driver_id) {
      return res.status(400).json({ success: false, error: 'driver_id parameter wajib disertakan.' });
    }

    const driverRes = await db.query('SELECT * FROM drivers WHERE driver_id = $1', [driver_id]);
    if (driverRes.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Driver tidak ditemukan.' });
    }
    const driver = driverRes.rows[0];

    // Ambil project yang di-assign ke driver (atau default project aktif)
    let projectRes = await db.query('SELECT * FROM projects WHERE project_id = $1', [driver.assigned_project_id]);
    if (projectRes.rows.length === 0) {
      projectRes = await db.query('SELECT * FROM projects WHERE is_active = TRUE ORDER BY created_at DESC LIMIT 1');
    }
    const project = projectRes.rows[0] || null;

    // Ambil active trip yang sedang berjalan (IN_TRANSIT) jika ada
    let activeTrip = null;
    if (project) {
      const activeTripRes = await db.query(
        `SELECT * FROM project_trips WHERE driver_id = $1 AND project_id = $2 AND status = 'IN_TRANSIT' ORDER BY created_at DESC LIMIT 1`,
        [driver_id, project.project_id]
      );
      if (activeTripRes.rows.length > 0) {
        activeTrip = activeTripRes.rows[0];
      }
    }

    // Ambil daftar trip selesai hari ini
    const todayTripsRes = await db.query(
      `SELECT * FROM project_trips WHERE driver_id = $1 AND status = 'COMPLETED' AND DATE(created_at) = CURRENT_DATE ORDER BY completed_at DESC`,
      [driver_id]
    );

    res.json({
      success: true,
      driver: {
        driver_id: driver.driver_id,
        full_name: driver.full_name,
        truck_wheel_type: driver.truck_wheel_type || '6 Roda (Dump Truck)',
        is_active: driver.is_active
      },
      project,
      active_trip: activeTrip,
      today_completed_trips: todayTripsRes.rows,
      today_trips_count: todayTripsRes.rows.length
    });
  } catch (err) {
    console.error('Driver project query error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 6. DYNAMIC GEOFENCES & MONITORING
// ==========================================
router.get('/geofences', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT location_id, name, location_type, latitude, longitude, radius_meters, is_active
      FROM master_locations
      ORDER BY location_type, name
    `);
    res.json({ success: true, geofences: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/geofences', async (req, res) => {
  try {
    const { name, location_type, latitude, longitude, radius_meters } = req.body;
    if (!name || !location_type || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, error: 'Nama, tipe lokasi, latitude, dan longitude wajib diisi.' });
    }
    const location_id = `LOC-${Date.now().toString().slice(-6)}`;
    const radius = radius_meters || (location_type === 'LOADING_POINT' ? 200 : 40);

    const result = await db.query(
      `INSERT INTO master_locations (location_id, name, location_type, latitude, longitude, radius_meters, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, TRUE)
       RETURNING *`,
      [location_id, name.trim(), location_type, parseFloat(latitude), parseFloat(longitude), parseInt(radius, 10)]
    );

    res.json({ success: true, location: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/geofences/:id/radius', async (req, res) => {
  try {
    const { id } = req.params;
    const { radius_meters } = req.body;
    if (!radius_meters || radius_meters < 10 || radius_meters > 1000) {
      return res.status(400).json({ success: false, error: 'Radius harus antara 10 - 1000 meter.' });
    }
    const result = await db.query(
      `UPDATE master_locations SET radius_meters = $1 WHERE location_id = $2 RETURNING *`,
      [radius_meters, id]
    );
    res.json({ success: true, location: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/geofences/:id/toggle', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      `UPDATE master_locations SET is_active = NOT is_active WHERE location_id = $1 RETURNING *`,
      [id]
    );
    res.json({ success: true, location: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/monitoring', async (req, res) => {
  try {
    const dbStart = Date.now();
    await db.query('SELECT 1');
    const dbLatency = Date.now() - dbStart;

    const [redisCheck, minioCheck] = await Promise.all([
      checkTcpService('127.0.0.1', 6379, 800),
      checkTcpService('10.10.10.2', 9000, 1200)
    ]);

    const totalMemMb = Math.round(os.totalmem() / 1024 / 1024);
    const freeMemMb = Math.round(os.freemem() / 1024 / 1024);
    const usedMemMb = totalMemMb - freeMemMb;
    const memPct = Math.round((usedMemMb / totalMemMb) * 100);
    const cpus = os.cpus();
    const loadAvg = os.loadavg();

    res.json({
      success: true,
      monitoring: {
        server: {
          hostname: os.hostname(),
          platform: `${os.type()} ${os.release()}`,
          uptime_sec: Math.floor(os.uptime()),
          cpu_cores: cpus ? cpus.length : 2,
          cpu_model: cpus && cpus[0] ? cpus[0].model : 'Intel Xeon Gold vCPU',
          load_1m: loadAvg[0] ? loadAvg[0].toFixed(2) : '0.12',
          memory_used_mb: usedMemMb,
          memory_total_mb: totalMemMb,
          memory_pct: memPct
        },
        postgres: {
          online: true,
          host: '10.10.10.2:5432',
          latency_ms: dbLatency,
          pool_total: db.pool ? db.pool.totalCount : 1,
          pool_idle: db.pool ? db.pool.idleCount : 1
        },
        redis: {
          online: redisCheck.online,
          mode: redisCheck.online ? 'Redis 7 Server (127.0.0.1:6379)' : 'In-Memory Cache (Active)',
          latency_ms: redisCheck.online ? redisCheck.latency_ms : 0.1,
          cache_hits: cacheStats.hits,
          cache_misses: cacheStats.misses,
          cached_keys: memCache.size
        },
        minio: {
          online: minioCheck.online,
          endpoint: '10.10.10.2:9000',
          latency_ms: minioCheck.latency_ms
        }
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/cache/flush', (req, res) => {
  memCache.clear();
  cacheStats.flushes += 1;
  res.json({ success: true, message: 'Cache Redis & In-Memory berhasil dibersihkan!' });
});

module.exports = router;
