// Mining & Geological Telematics Map Engine (Leaflet Adapter)
export class MiningMapService {
  constructor(containerId = 'map') {
    this.containerId = containerId;
    this.map = null;
    this.tileLayers = {};
    this.currentTileLayer = null;
    this.fleetMarkers = {};
    this.locationLayers = [];
    this.routePolylines = [];
    this.onTruckSelectedCallback = null;
    this.hasFittedInitialBounds = false;

    // Vibrant Distinct Driver Color Palette (High Visibility on Dark & Satellite Tiles)
    this.driverColorPalette = [
      { border: '#3B82F6', bg: 'rgba(59, 130, 246, 0.2)', text: '#60A5FA', label: 'Biru Cobalt' },      // Driver 1: Ahmad Fauzi
      { border: '#F59E0B', bg: 'rgba(245, 158, 11, 0.2)', text: '#FBBF24', label: 'Kuning Amber' },     // Driver 2: Budi Santoso
      { border: '#EC4899', bg: 'rgba(236, 72, 153, 0.2)', text: '#F472B6', label: 'Magenta Pink' },     // Driver 3: Hendra Saputra
      { border: '#10B981', bg: 'rgba(16, 185, 129, 0.2)', text: '#34D399', label: 'Hijau Emerald' },    // Driver 4
      { border: '#8B5CF6', bg: 'rgba(139, 92, 246, 0.2)', text: '#A78BFA', label: 'Ungu Violet' },      // Driver 5
      { border: '#06B6D4', bg: 'rgba(6, 182, 212, 0.2)', text: '#22D3EE', label: 'Cyan Elektrik' },     // Driver 6
      { border: '#F97316', bg: 'rgba(249, 115, 22, 0.2)', text: '#FB923C', label: 'Jingga Safety' },    // Driver 7
      { border: '#14B8A6', bg: 'rgba(20, 184, 166, 0.2)', text: '#2DD4BF', label: 'Teal Mint' },        // Driver 8
    ];
  }

  getDriverColor(driverIdentifier) {
    if (!driverIdentifier) return this.driverColorPalette[0];
    let hash = 0;
    const str = String(driverIdentifier);
    for (let i = 0; i < str.length; i++) {
      hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    const index = Math.abs(hash) % this.driverColorPalette.length;
    return this.driverColorPalette[index];
  }

  initMap(centerCoords = [-3.138, 115.132], defaultZoom = 13) {
    const container = document.getElementById(this.containerId);
    if (!container) return;

    this.map = L.map(this.containerId, {
      center: centerCoords,
      zoom: defaultZoom,
      zoomControl: false,
      attributionControl: false
    });

    L.control.zoom({ position: 'bottomright' }).addTo(this.map);

    this.tileLayers['GIS_DARK'] = L.tileLayer(
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      { maxZoom: 19, subdomains: 'abcd' }
    );

    this.tileLayers['SATELLITE'] = L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      { maxZoom: 18 }
    );

    this.applyTileLayer('SATELLITE');
  }

  applyTileLayer(layerKey) {
    if (!this.map || !this.tileLayers[layerKey]) return;
    if (this.currentTileLayer) {
      this.map.removeLayer(this.currentTileLayer);
    }
    this.tileLayers[layerKey].addTo(this.map);
    this.currentTileLayer = this.tileLayers[layerKey];
  }

  setTheme(theme) {
    if (theme === 'LIGHT') {
      if (!this.tileLayers['GIS_LIGHT']) {
        this.tileLayers['GIS_LIGHT'] = L.tileLayer(
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          { maxZoom: 19, subdomains: 'abcd' }
        );
      }
      this.applyTileLayer('GIS_LIGHT');
    } else {
      this.applyTileLayer('SATELLITE');
    }
  }

  renderLocations(locations) {
    if (!this.map) return;
    this.locationLayers.forEach(l => this.map.removeLayer(l));
    this.locationLayers = [];

    const validCoords = [];

    locations.forEach(loc => {
      if (!loc.lat || !loc.lng || !loc.is_active) return;
      validCoords.push([loc.lat, loc.lng]);

      const isLoad = loc.type === 'LOADING_POINT';
      const color = isLoad ? '#F59E0B' : '#10B981';

      const circle = L.circle([loc.lat, loc.lng], {
        radius: loc.radius || (isLoad ? 250 : 40),
        color: color,
        fillColor: color,
        fillOpacity: 0.14,
        weight: 1.8,
        dashArray: isLoad ? '5, 5' : null
      }).addTo(this.map);

      const labelHtml = `
        <div style="
          background: #0F172A;
          border: 1.5px solid ${color};
          color: #F8FAFC;
          font-family: 'Inter', -apple-system, sans-serif;
          font-size: 11px;
          font-weight: 700;
          padding: 3px 8px;
          border-radius: 6px;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.6);
          white-space: nowrap;
          display: flex;
          align-items: center;
          gap: 6px;
        ">
          <span style="width: 7px; height: 7px; border-radius: 50%; background: ${color};"></span>
          <span>${loc.name} (${loc.radius || (isLoad ? 250 : 40)}m)</span>
        </div>
      `;

      const labelIcon = L.divIcon({
        html: labelHtml,
        className: 'custom-location-label',
        iconSize: null,
        iconAnchor: [60, 28]
      });

      const marker = L.marker([loc.lat, loc.lng], { icon: labelIcon }).addTo(this.map);
      marker.bindPopup(`
        <div style="font-family: 'Inter', sans-serif; padding: 4px;">
          <div style="font-weight: 700; color: #0F172A; font-size: 13px; margin-bottom: 4px;">${loc.name}</div>
          <div style="font-size: 11px; color: #475569;">Tipe: <b>${isLoad ? 'Titik Muat (Pit)' : 'Titik Bongkar (ROM)'}</b></div>
          <div style="font-size: 11px; color: #475569;">Radius Geofence: <b style="color: ${color};">${loc.radius || (isLoad ? 250 : 40)} meter</b></div>
          <div style="font-size: 11px; color: #64748B; margin-top: 3px;">${loc.lat.toFixed(5)}, ${loc.lng.toFixed(5)}</div>
        </div>
      `);

      this.locationLayers.push(circle, marker);
    });

    if (!this.hasFittedInitialBounds && validCoords.length > 0) {
      this.hasFittedInitialBounds = true;
      const bounds = L.latLngBounds(validCoords);
      this.map.fitBounds(bounds, { padding: [60, 60], maxZoom: 14 });
    }
  }

  // Render Fleet dengan WARNA UNIK PER DRIVER
  renderLiveFleet(fleet) {
    if (!this.map) return;
    Object.values(this.fleetMarkers).forEach(m => this.map.removeLayer(m));
    this.fleetMarkers = {};

    fleet.forEach(truck => {
      if (!truck.current_lat || !truck.current_lng) return;

      // Ambil warna unik khusus untuk driver ini
      const driverColor = this.getDriverColor(truck.driver_id || truck.driver_name);
      const wheelLabel = truck.model ? truck.model.split(' ')[0] : '6-Roda';

      const iconHtml = `
        <div style="
          background: #0B0E14;
          border: 2px solid ${driverColor.border};
          border-radius: 9px;
          padding: 4px 10px;
          color: #F8FAFC;
          font-family: 'Inter', -apple-system, sans-serif;
          font-size: 11.5px;
          font-weight: 700;
          display: inline-flex;
          align-items: center;
          gap: 6px;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.8), 0 0 10px ${driverColor.bg};
          white-space: nowrap;
          width: max-content;
          cursor: pointer;
          line-height: 1;
        ">
          <span style="
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: ${driverColor.border};
            box-shadow: 0 0 8px ${driverColor.border};
          "></span>
          <span style="color: ${driverColor.text}; font-family: 'JetBrains Mono', monospace; font-size: 10.5px;">[${wheelLabel}]</span>
          <span>${truck.driver_name}</span>
          <span style="
            background: ${driverColor.bg};
            color: ${driverColor.text};
            padding: 2px 5px;
            border-radius: 4px;
            font-size: 9.5px;
            font-weight: 700;
          ">${truck.unit_id}</span>
        </div>
      `;

      const customIcon = L.divIcon({
        html: iconHtml,
        className: 'custom-truck-marker',
        iconSize: null,
        iconAnchor: [60, 16]
      });

      const marker = L.marker([truck.current_lat, truck.current_lng], { icon: customIcon }).addTo(this.map);
      marker.on('click', () => {
        if (this.onTruckSelectedCallback) {
          this.onTruckSelectedCallback(truck, driverColor);
        }
      });
      this.fleetMarkers[truck.unit_id] = marker;
    });
  }

  renderTaskRoute(task) {
    this.clearRoutes();
    if (!this.map) return;

    let routeCoords = task.actual_route || [];
    if (routeCoords.length === 0 && task.start_lat && task.start_lng && task.end_lat && task.end_lng) {
      routeCoords = [
        [parseFloat(task.start_lat), parseFloat(task.start_lng)],
        [parseFloat(task.end_lat), parseFloat(task.end_lng)]
      ];
    }

    if (routeCoords.length === 0) return;

    const driverColor = this.getDriverColor(task.driver_id || task.driver_name);

    const polylineGlow = L.polyline(routeCoords, {
      color: driverColor.bg,
      weight: 8,
      smoothFactor: 1
    }).addTo(this.map);

    const polylineCore = L.polyline(routeCoords, {
      color: driverColor.border,
      weight: 3.5,
      dashArray: (!task.actual_route || task.actual_route.length === 0) ? '6, 6' : null,
      smoothFactor: 1
    }).addTo(this.map);

    this.routePolylines.push(polylineGlow, polylineCore);
  }

  clearRoutes() {
    if (!this.map) return;
    this.routePolylines.forEach(p => this.map.removeLayer(p));
    this.routePolylines = [];
  }
}
