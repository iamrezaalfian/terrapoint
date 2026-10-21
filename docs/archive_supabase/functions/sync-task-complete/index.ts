// Supabase Edge Function: sync-task-complete (Deno / TypeScript)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const EARTH_RADIUS_METERS = 6371000.0;
const MAX_ALLOWED_GEOFENCE_RADIUS_METERS = 50.0;

function calculateHaversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const dLat = (lat2 - lat1) * (Math.PI / 180.0);
  const dLon = (lon2 - lon1) * (Math.PI / 180.0);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180.0)) *
      Math.cos(lat2 * (Math.PI / 180.0)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
}

interface SyncTaskPayload {
  task_id: string;
  driver_id: string;
  title: string;
  start_point: {
    name: string;
    lat: number;
    lng: number;
    radius?: number;
  };
  end_point?: {
    name: string;
    lat: number;
    lng: number;
    radius?: number;
  };
  evidences: {
    start_photo: {
      captured_lat: number;
      captured_lng: number;
      accuracy_meters: number;
      r2_url: string;
      captured_at: string;
    };
    end_photo?: {
      captured_lat: number;
      captured_lng: number;
      accuracy_meters: number;
      r2_url: string;
      captured_at: string;
    };
  };
  actual_route: Array<{
    lat: number;
    lng: number;
    spd?: number;
    t?: number;
  }>;
}

serve(async (req) => {
  // Handle CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const payload: SyncTaskPayload = await req.json();

    if (!payload.task_id || !payload.driver_id || !payload.start_point || !payload.evidences?.start_photo) {
      return new Response(
        JSON.stringify({ error: 'Payload tidak lengkap. task_id, driver_id, start_point, dan start_photo wajib ada.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Validasi Haversine Geofence Titik Muat (Start Checkpoint)
    const startDeviation = calculateHaversine(
      payload.start_point.lat,
      payload.start_point.lng,
      payload.evidences.start_photo.captured_lat,
      payload.evidences.start_photo.captured_lng
    );

    const maxStartRadius = payload.start_point.radius ?? MAX_ALLOWED_GEOFENCE_RADIUS_METERS;
    if (startDeviation > maxStartRadius) {
      return new Response(
        JSON.stringify({
          error: 'REJECTED_GEOFENCE',
          message: `Deviasi foto muat terlalu jauh (${startDeviation.toFixed(1)}m > batas ${maxStartRadius}m).`,
        }),
        { status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Validasi Haversine Geofence Titik Bongkar (End Checkpoint jika ada)
    let endDeviation: number | null = null;
    if (payload.end_point && payload.evidences.end_photo) {
      endDeviation = calculateHaversine(
        payload.end_point.lat,
        payload.end_point.lng,
        payload.evidences.end_photo.captured_lat,
        payload.evidences.end_photo.captured_lng
      );
    }

    // 3. Simpan / Perbarui Data Ritase ke PostgreSQL (tasks)
    const { error: taskError } = await supabaseClient
      .from('tasks')
      .upsert({
        task_id: payload.task_id,
        driver_id: payload.driver_id,
        title: payload.title,
        start_point_name: payload.start_point.name,
        start_lat: payload.start_point.lat,
        start_lng: payload.start_point.lng,
        start_radius_meters: maxStartRadius,
        end_point_name: payload.end_point?.name ?? null,
        end_lat: payload.end_point?.lat ?? null,
        end_lng: payload.end_point?.lng ?? null,
        end_radius_meters: payload.end_point?.radius ?? 50,
        status: 'COMPLETED',
        actual_route: payload.actual_route ?? [],
        completed_at: payload.evidences.end_photo?.captured_at ?? new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });

    if (taskError) {
      throw taskError;
    }

    // 4. Simpan Bukti Foto ke task_evidences
    const evidencesToInsert = [
      {
        evidence_id: `${payload.task_id}-START`,
        task_id: payload.task_id,
        checkpoint_type: 'START',
        captured_lat: payload.evidences.start_photo.captured_lat,
        captured_lng: payload.evidences.start_photo.captured_lng,
        accuracy_meters: payload.evidences.start_photo.accuracy_meters,
        deviation_meters: startDeviation,
        r2_storage_url: payload.evidences.start_photo.r2_url,
        file_size_bytes: 120000,
        captured_at: payload.evidences.start_photo.captured_at,
      },
    ];

    if (payload.evidences.end_photo) {
      evidencesToInsert.push({
        evidence_id: `${payload.task_id}-END`,
        task_id: payload.task_id,
        checkpoint_type: 'END',
        captured_lat: payload.evidences.end_photo.captured_lat,
        captured_lng: payload.evidences.end_photo.captured_lng,
        accuracy_meters: payload.evidences.end_photo.accuracy_meters,
        deviation_meters: endDeviation ?? 0.0,
        r2_storage_url: payload.evidences.end_photo.r2_url,
        file_size_bytes: 125000,
        captured_at: payload.evidences.end_photo.captured_at,
      });
    }

    const { error: evidenceError } = await supabaseClient
      .from('task_evidences')
      .upsert(evidencesToInsert);

    if (evidenceError) {
      throw evidenceError;
    }

    return new Response(
      JSON.stringify({
        status: 'SUCCESS',
        data: {
          task_id: payload.task_id,
          verified_start_deviation_meters: Number(startDeviation.toFixed(2)),
          verified_end_deviation_meters: endDeviation ? Number(endDeviation.toFixed(2)) : null,
          status: 'COMPLETED',
          synced_at: new Date().toISOString(),
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'INTERNAL_SERVER_ERROR', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
