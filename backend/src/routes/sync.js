const express = require('express');
const db = require('../db');
const { calculateHaversine, MAX_ALLOWED_GEOFENCE_RADIUS_METERS } = require('../utils/haversine');

const router = express.Router();

/**
 * POST /api/sync/task-complete
 * Menggantikan Supabase Edge Function 'sync-task-complete'
 * Memvalidasi Haversine Geofence 50m secara independen di server VPS
 */
router.post('/task-complete', async (req, res) => {
  const client = await db.pool.connect();
  try {
    const payload = req.body;
    const {
      task_id,
      driver_id,
      title,
      start_point,
      end_point,
      evidences,
      actual_route = [],
    } = payload;

    if (!task_id || !driver_id || !start_point) {
      return res.status(400).json({
        success: false,
        error: 'Data wajib belum lengkap (task_id, driver_id, start_point diperlukan).',
      });
    }

    // 1. Validasi Haversine Start Checkpoint (Pit)
    let startDeviation = 0.0;
    if (evidences && evidences.start) {
      startDeviation = calculateHaversine(
        start_point.lat,
        start_point.lng,
        evidences.start.captured_lat,
        evidences.start.captured_lng
      );
    }

    // 2. Validasi Haversine End Checkpoint (ROM / Smelter)
    let endDeviation = 0.0;
    let isGeofenceBreached = false;

    if (end_point && evidences && evidences.end) {
      endDeviation = calculateHaversine(
        end_point.lat,
        end_point.lng,
        evidences.end.captured_lat,
        evidences.end.captured_lng
      );
    }

    const startTolerance = start_point.radius || MAX_ALLOWED_GEOFENCE_RADIUS_METERS;
    const endTolerance = end_point?.radius || MAX_ALLOWED_GEOFENCE_RADIUS_METERS;

    if (startDeviation > startTolerance || (evidences?.end && endDeviation > endTolerance)) {
      isGeofenceBreached = true;
    }

    const finalStatus = isGeofenceBreached ? 'REJECTED_GEOFENCE' : 'COMPLETED';

    await client.query('BEGIN');

    // 3. Upsert Task ke tabel tasks
    const upsertTaskQuery = `
      INSERT INTO tasks (
        task_id, driver_id, title,
        start_point_name, start_lat, start_lng, start_radius_meters,
        end_point_name, end_lat, end_lng, end_radius_meters,
        is_tracking_enabled, actual_route, status, completed_at, updated_at
      ) VALUES (
        $1, $2, $3,
        $4, $5, $6, $7,
        $8, $9, $10, $11,
        TRUE, $12, $13, NOW(), NOW()
      )
      ON CONFLICT (task_id) DO UPDATE SET
        end_point_name = EXCLUDED.end_point_name,
        end_lat = EXCLUDED.end_lat,
        end_lng = EXCLUDED.end_lng,
        actual_route = EXCLUDED.actual_route,
        status = EXCLUDED.status,
        completed_at = EXCLUDED.completed_at,
        updated_at = NOW();
    `;

    await client.query(upsertTaskQuery, [
      task_id,
      driver_id,
      title || 'Hauling Pit - ROM Smelter',
      start_point.name,
      start_point.lat,
      start_point.lng,
      startTolerance,
      end_point ? end_point.name : null,
      end_point ? end_point.lat : null,
      end_point ? end_point.lng : null,
      endTolerance,
      JSON.stringify(actual_route),
      finalStatus,
    ]);

    // 4. Upsert Evidences (Start & End)
    if (evidences) {
      const upsertEvidenceQuery = `
        INSERT INTO task_evidences (
          evidence_id, task_id, checkpoint_type,
          captured_lat, captured_lng, accuracy_meters, deviation_meters,
          r2_storage_url, file_size_bytes, captured_at, verified_at
        ) VALUES (
          $1, $2, $3,
          $4, $5, $6, $7,
          $8, $9, $10, NOW()
        )
        ON CONFLICT (task_id, checkpoint_type) DO UPDATE SET
          captured_lat = EXCLUDED.captured_lat,
          captured_lng = EXCLUDED.captured_lng,
          deviation_meters = EXCLUDED.deviation_meters,
          r2_storage_url = EXCLUDED.r2_storage_url,
          verified_at = NOW();
      `;

      if (evidences.start) {
        const ev = evidences.start;
        await client.query(upsertEvidenceQuery, [
          `ev-start-${task_id}`,
          task_id,
          'START',
          ev.captured_lat,
          ev.captured_lng,
          ev.accuracy_meters || 4.2,
          startDeviation,
          ev.r2_storage_url || ev.storage_url || '',
          ev.file_size_bytes || 0,
          ev.captured_at || new Date().toISOString(),
        ]);
      }

      if (evidences.end) {
        const ev = evidences.end;
        await client.query(upsertEvidenceQuery, [
          `ev-end-${task_id}`,
          task_id,
          'END',
          ev.captured_lat,
          ev.captured_lng,
          ev.accuracy_meters || 4.5,
          endDeviation,
          ev.r2_storage_url || ev.storage_url || '',
          ev.file_size_bytes || 0,
          ev.captured_at || new Date().toISOString(),
        ]);
      }
    }

    // 5. Simpan Rute Breadcrumbs ke task_raw_breadcrumbs jika disertakan
    if (actual_route.length > 0) {
      for (const pt of actual_route) {
        await client.query(
          `INSERT INTO task_raw_breadcrumbs (task_id, latitude, longitude, speed_kmh, heading, recorded_at)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (task_id, recorded_at) DO NOTHING`,
          [
            task_id,
            pt.lat,
            pt.lng,
            pt.speed || 0,
            pt.heading || 0,
            pt.time || new Date().toISOString(),
          ]
        );
      }
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      task_id,
      status: finalStatus,
      is_geofence_breached: isGeofenceBreached,
      start_deviation_meters: Math.round(startDeviation * 10) / 10,
      end_deviation_meters: Math.round(endDeviation * 10) / 10,
      message: isGeofenceBreached
        ? 'Peringatan K3: Bukti foto berada di luar radius toleransi 50m geofence!'
        : 'Ritase berhasil diverifikasi dan tersinkronisasi ke server VPS.',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Sync task error:', err);
    res.status(500).json({ success: false, error: err.message });
  } finally {
    client.release();
  }
});

/**
 * POST /api/sync/breadcrumbs
 * Background telemetry ingestion stream dari aplikasi pengemudi
 */
router.post('/breadcrumbs', async (req, res) => {
  try {
    const { task_id, breadcrumbs = [] } = req.body;
    if (!task_id || breadcrumbs.length === 0) {
      return res.json({ success: true, count: 0 });
    }

    let inserted = 0;
    for (const b of breadcrumbs) {
      await db.query(
        `INSERT INTO task_raw_breadcrumbs (task_id, latitude, longitude, speed_kmh, heading, recorded_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (task_id, recorded_at) DO NOTHING`,
        [
          task_id,
          b.latitude || b.lat,
          b.longitude || b.lng,
          b.speed_kmh || b.speed || 0,
          b.heading || 0,
          b.recorded_at || new Date().toISOString(),
        ]
      );
      inserted++;
    }

    res.json({ success: true, count: inserted });
  } catch (err) {
    console.error('Breadcrumbs sync error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});
// ==========================================
// PROJECT TRIPS HAULING LIFECYCLE (LOAD & DUMP)
// ==========================================

/**
 * POST /api/sync/trip-load
 * Rekam Muat di Titik Muat (Pit) - Radius Luas
 */
router.post('/trip-load', async (req, res) => {
  try {
    const { project_id, driver_id, truck_wheel_type = '6 Roda (Dump Truck)', load_photo_url, load_lat, load_lng } = req.body;
    if (!project_id || !driver_id) {
      return res.status(400).json({ success: false, error: 'project_id dan driver_id wajib disertakan.' });
    }

    const prjRes = await db.query('SELECT * FROM projects WHERE project_id = $1', [project_id]);
    if (prjRes.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Proyek tidak ditemukan.' });
    }
    const project = prjRes.rows[0];

    // Hitung deviasi ke Titik Muat
    let dev = 0.0;
    if (load_lat && load_lng) {
      dev = calculateHaversine(project.start_lat, project.start_lng, load_lat, load_lng);
    }

    // Sequence trip hari ini untuk driver
    const countRes = await db.query(
      `SELECT COUNT(*) as count FROM project_trips WHERE driver_id = $1 AND DATE(created_at) = CURRENT_DATE`,
      [driver_id]
    );
    const seq = parseInt(countRes.rows[0].count, 10) + 1;

    const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const randCode = Math.floor(100 + Math.random() * 900);
    const trip_id = `TRP-${todayStr}-${randCode}`;

    // Update profil driver jika jenis roda mobil diganti oleh driver di mobile
    if (truck_wheel_type) {
      await db.query('UPDATE drivers SET truck_wheel_type = $1 WHERE driver_id = $2', [truck_wheel_type, driver_id]);
    }

    const insertTrip = `
      INSERT INTO project_trips (
        trip_id, project_id, driver_id, truck_wheel_type, trip_sequence,
        status, load_photo_url, load_lat, load_lng, load_deviation_m, load_at, created_at
      ) VALUES ($1, $2, $3, $4, $5, 'IN_TRANSIT', $6, $7, $8, $9, NOW(), NOW())
      RETURNING *
    `;
    const result = await db.query(insertTrip, [
      trip_id,
      project_id,
      driver_id,
      truck_wheel_type,
      seq,
      load_photo_url || null,
      load_lat ? parseFloat(load_lat) : null,
      load_lng ? parseFloat(load_lng) : null,
      Math.round(dev * 10) / 10
    ]);

    res.json({
      success: true,
      trip: result.rows[0],
      message: `Muatan Trip #${seq} berhasil dicatat! Menuju ${project.end_point_name}.`
    });
  } catch (err) {
    console.error('Trip load error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/sync/trip-dump-step
 * Rekam Foto Pembongkaran Curah di ROM (Card 2) - Progress status
 */
router.post('/trip-dump-step', async (req, res) => {
  try {
    const { trip_id, dump_photo_url, dump_lat, dump_lng } = req.body;
    if (!trip_id) {
      return res.status(400).json({ success: false, error: 'trip_id wajib disertakan.' });
    }

    const tripRes = await db.query(
      `SELECT pt.*, p.end_lat, p.end_lng FROM project_trips pt JOIN projects p ON pt.project_id = p.project_id WHERE pt.trip_id = $1`,
      [trip_id]
    );
    if (tripRes.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Trip tidak ditemukan.' });
    }
    const trip = tripRes.rows[0];

    let dev = 0.0;
    if (dump_lat && dump_lng) {
      dev = calculateHaversine(trip.end_lat, trip.end_lng, dump_lat, dump_lng);
    }

    const result = await db.query(`
      UPDATE project_trips SET
        dump_photo_url = COALESCE($1, dump_photo_url),
        dump_lat = COALESCE($2, dump_lat),
        dump_lng = COALESCE($3, dump_lng),
        dump_deviation_m = $4,
        dump_at = NOW()
      WHERE trip_id = $5
      RETURNING *
    `, [dump_photo_url, dump_lat ? parseFloat(dump_lat) : null, dump_lng ? parseFloat(dump_lng) : null, Math.round(dev * 10) / 10, trip_id]);

    res.json({ success: true, trip: result.rows[0], message: 'Foto pembongkaran berhasil dicatat. Silakan lanjutkan foto nota timbang.' });
  } catch (err) {
    console.error('Trip dump step error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/sync/trip-dump
 * Rekam Bongkar & Foto Nota / Invoice di Titik Bongkar (ROM) - Radius Kecil
 */
router.post('/trip-dump', async (req, res) => {
  try {
    const { trip_id, dump_photo_url, invoice_photo_url, dump_lat, dump_lng } = req.body;
    if (!trip_id) {
      return res.status(400).json({ success: false, error: 'trip_id wajib disertakan.' });
    }

    const tripRes = await db.query(
      `SELECT pt.*, p.end_lat, p.end_lng, p.end_radius_meters, p.end_point_name
       FROM project_trips pt
       JOIN projects p ON pt.project_id = p.project_id
       WHERE pt.trip_id = $1`,
      [trip_id]
    );

    if (tripRes.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Data trip tidak ditemukan.' });
    }
    const trip = tripRes.rows[0];

    // Hitung deviasi ke Titik Bongkar
    let dev = 0.0;
    if (dump_lat && dump_lng) {
      dev = calculateHaversine(trip.end_lat, trip.end_lng, dump_lat, dump_lng);
    }

    const updateQuery = `
      UPDATE project_trips SET
        status = 'COMPLETED',
        dump_photo_url = $1,
        invoice_photo_url = $2,
        dump_lat = $3,
        dump_lng = $4,
        dump_deviation_m = $5,
        dump_at = NOW(),
        completed_at = NOW()
      WHERE trip_id = $6
      RETURNING *
    `;

    const result = await db.query(updateQuery, [
      dump_photo_url || null,
      invoice_photo_url || null, // FOTO NOTA / INVOICE
      dump_lat ? parseFloat(dump_lat) : null,
      dump_lng ? parseFloat(dump_lng) : null,
      Math.round(dev * 10) / 10,
      trip_id
    ]);

    res.json({
      success: true,
      trip: result.rows[0],
      message: `Trip #${trip.trip_sequence} selesai! Pembongkaran & nota timbang terverifikasi.`
    });
  } catch (err) {
    console.error('Trip dump error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
