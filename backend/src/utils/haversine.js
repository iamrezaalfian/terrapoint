const EARTH_RADIUS_METERS = 6371000.0;

/**
 * Menghitung jarak garis lurus antara dua titik koordinat GPS (formula Haversine)
 * @param {number} lat1 
 * @param {number} lon1 
 * @param {number} lat2 
 * @param {number} lon2 
 * @returns {number} Jarak dalam satuan meter
 */
function calculateHaversine(lat1, lon1, lat2, lon2) {
  const toRad = (angle) => (angle * Math.PI) / 180.0;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
}

module.exports = {
  calculateHaversine,
  MAX_ALLOWED_GEOFENCE_RADIUS_METERS: 50.0,
};
