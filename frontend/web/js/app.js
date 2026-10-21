// TerraPoint Admin Fleet Telematics & Operations Command Center Controller
import { MASTER_CHECKPOINTS, LIVE_FLEET_TELEMETRY, INITIAL_SETTINGS, DEFAULT_SITE_CENTER } from './mock_data.js';
import { MiningMapService } from './map_service.js';
import { Icons } from './icons.js';

class DispatcherApp {
  constructor() {
    this.mapService = new MiningMapService('map');
    this.projects = [];
    this.trips = [];
    this.tasks = [];
    this.locations = [...MASTER_CHECKPOINTS];
    this.drivers = [];
    this.fleet = [...LIVE_FLEET_TELEMETRY];
    this.settings = { ...INITIAL_SETTINGS };
    this.currentPage = 'page-live-map';
    this.currentTheme = localStorage.getItem('terrapoint_theme') || 'DARK';
    this.isSidebarCollapsed = localStorage.getItem('terrapoint_sidebar_collapsed') === 'true';
    this.isLoggedIn = true;
    this.currentUser = {
      name: 'Ahmad Fauzi',
      email: 'ahmad.fauzi@terrapoint.id',
      role: 'Head Mine Dispatcher'
    };
  }

  init() {
    this.applyTheme(this.currentTheme);
    this.applySidebarState(this.isSidebarCollapsed);
    this.injectIcons();
    this.setupSidebarToggle();
    this.setupThemeToggle();
    this.setupUserDropdownAndLogin();
    this.setupNavigation();
    this.setupPage1LiveMap();
    this.setupProjectsAndTrips();
    this.setupPage2TripLogs();
    this.setupDriversManagement();
    this.setupPage3Geofence();
    this.setupPage5Settings();
    this.setupEvidenceModal();
    this.setupMapToolbarAndHUD();
    this.registerServiceWorker();
    this.startWitaClock();
    this.fetchLiveBackendData();
    setInterval(() => this.fetchLiveBackendData(), 8000);
  }

  startWitaClock() {
    const clockEl = document.getElementById('sidebar-wita-clock');
    if (!clockEl) return;
    const update = () => {
      const now = new Date();
      const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
      const wita = new Date(utc + (3600000 * 8));
      const hours = String(wita.getHours()).padStart(2, '0');
      const mins = String(wita.getMinutes()).padStart(2, '0');
      const secs = String(wita.getSeconds()).padStart(2, '0');
      clockEl.textContent = `${hours}:${mins}:${secs} WITA (UTC+8)`;
    };
    update();
    setInterval(update, 1000);
  }

  async fetchLiveBackendData() {
    try {
      // 1. Fetch live KPI Summary with Wheel-type Breakdown
      const sumRes = await fetch('/api/dashboard/summary');
      if (sumRes.ok) {
        const sumJson = await sumRes.json();
        if (sumJson && sumJson.success && sumJson.data) {
          this.renderWheelKPIs(sumJson.data);
        }
      }

      // 2. Fetch live Projects
      const prjRes = await fetch('/api/dashboard/projects');
      if (prjRes.ok) {
        const prjJson = await prjRes.json();
        if (prjJson && prjJson.success && Array.isArray(prjJson.projects)) {
          this.projects = prjJson.projects;
          this.renderProjectsTable(this.projects);
          this.populateProjectDropdowns(this.projects);
        }
      }

      // 3. Fetch live Trips (Pengantaran dengan Bukti Nota & Foto)
      const trpRes = await fetch('/api/dashboard/trips');
      if (trpRes.ok) {
        const trpJson = await trpRes.json();
        if (trpJson && trpJson.success && Array.isArray(trpJson.trips)) {
          this.trips = trpJson.trips;
          this.renderLiveMapTripsTable(this.trips);
          this.renderTripLogsTable(this.trips);
        }
      }

      // 4. Fetch live Drivers
      const drvRes = await fetch('/api/dashboard/drivers');
      if (drvRes.ok) {
        const drvJson = await drvRes.json();
        if (drvJson && drvJson.success && Array.isArray(drvJson.drivers)) {
          this.drivers = drvJson.drivers;
          this.renderDriversTable(this.drivers);
          this.populateDriverDropdowns(this.drivers);

          // Update fleet positions
          const defaultLoc = this.locations[0] || { lat: -3.131, lng: 115.119 };
          this.fleet = this.drivers.map((d, idx) => {
            const unitNum = String(idx + 1).padStart(2, '0');
            const act = d.active_trip;
            return {
              unit_id: `DT-${unitNum}`,
              model: d.truck_wheel_type || '6 Roda (Dump Truck)',
              fleet_group: 'Armada Operasional',
              driver_id: d.driver_id,
              driver_name: d.full_name,
              driver_nik: d.driver_id,
              status: act ? 'HAULING' : (d.is_active ? 'STANDBY' : 'NONAKTIF'),
              payload_ton: act ? 45.0 : 0,
              material_type: act ? 'Muatan Berjalan' : 'Siap Bertugas',
              current_lat: defaultLoc.lat - (idx * 0.003),
              current_lng: defaultLoc.lng + (idx * 0.003),
              elevation_msl: 85,
              speed_kmh: act ? 32.5 : 0.0,
              fuel_level_pct: 88 - (idx * 4),
              fuel_burn_rate_lph: act ? 15.2 : 2.0,
              engine_temp_c: 84,
              tire_pressure_psi: 110,
              haul_cycle_stage: act ? `${d.assigned_project_name || 'Proyek'}` : 'Standby Menunggu Ritase'
            };
          });

          if (this.mapService) {
            this.mapService.renderLiveFleet(this.fleet);
          }
        }
      }

      // 5. Fetch live Geofences (Titik Muat & Titik Bongkar)
      const geoRes = await fetch('/api/dashboard/geofences');
      if (geoRes.ok) {
        const geoJson = await geoRes.json();
        if (geoJson && geoJson.success && Array.isArray(geoJson.geofences)) {
          this.locations = geoJson.geofences.map(g => ({
            location_id: g.location_id,
            code: g.location_id.replace('LOC-', ''),
            name: g.name,
            type: g.location_type,
            lat: parseFloat(g.latitude),
            lng: parseFloat(g.longitude),
            radius: parseInt(g.radius_meters, 10),
            color: g.location_type === 'LOADING_POINT' ? '#F59E0B' : '#10B981',
            is_active: g.is_active
          }));
          if (this.mapService) {
            this.mapService.renderLocations(this.locations);
          }
          this.renderGeofenceTable(this.locations);
          this.populateLocationDropdowns(this.locations);
        }
      }
    } catch (e) {
      console.warn('Live API sync notice:', e);
    }
  }

  injectIcons() {
    try {
      const iconMap = {
        'brand-logo-icon': Icons.betterAuth?.(22) || '',
        'icon-sidebar-toggle': Icons.panelLeft?.(18) || '',
        'icon-theme-toggle': (this.currentTheme === 'DARK' ? Icons.sun?.(18) : Icons.moon?.(18)) || '',
        'icon-user-avatar': Icons.user?.(16) || '',
        'icon-nav-map': Icons.map?.(18) || '',
        'icon-nav-tasks': Icons.briefcase?.(18) || Icons.clipboardList?.(18) || '',
        'icon-nav-drivers': Icons.users?.(18) || '',
        'icon-nav-logs': Icons.clipboard?.(18) || Icons.clipboardList?.(18) || '',
        'icon-nav-fleet': Icons.truck?.(18) || '',
        'icon-nav-settings': Icons.settings?.(18) || '',
        'icon-nav-mobile': Icons.camera?.(18) || '',
        'icon-top-assign': Icons.plus?.(15) || '',
        'icon-map-sat': Icons.layers?.(16) || '',
        'icon-map-gis': Icons.crosshair?.(16) || '',
        'icon-map-fit': Icons.maximize?.(16) || '',
        'icon-search-map': Icons.search?.(14) || '',
        'icon-search-logs': Icons.search?.(14) || '',
        'icon-search-geofence': Icons.search?.(14) || '',
        'icon-search-tasks': Icons.search?.(14) || '',
        'icon-search-drivers': Icons.search?.(14) || '',
        'icon-search-fleet': Icons.search?.(14) || '',
        'icon-assign-task-action': Icons.plus?.(15) || '',
        'icon-add-checkpoint': Icons.plus?.(15) || '',
        'icon-add-driver-btn': Icons.plus?.(15) || '',
        'icon-export-csv': Icons.download?.(14) || '',
        'icon-hud-close': Icons.x?.(16) || '',
        'icon-dropdown-logout': Icons.logOut?.(14) || '',
        'login-brand-logo': Icons.truck?.(36) || '',
        'icon-login-user': Icons.user?.(16) || '',
        'icon-login-pass': Icons.shield?.(16) || '',
        'icon-eye-toggle': Icons.eye?.(16) || '',
        'modal-shield-icon': Icons.shield?.(18) || ''
      };

      Object.entries(iconMap).forEach(([id, svg]) => {
        const el = document.getElementById(id);
        if (el && svg) el.innerHTML = svg;
      });
    } catch (e) {
      console.warn('Icon injection warning:', e);
    }
  }

  setupSidebarToggle() {
    const toggleBtn = document.getElementById('btn-toggle-sidebar');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.isSidebarCollapsed = !this.isSidebarCollapsed;
        this.applySidebarState(this.isSidebarCollapsed);
      });
    }
    const brandLogo = document.getElementById('brand-logo-icon');
    if (brandLogo) {
      brandLogo.addEventListener('click', () => {
        if (this.isSidebarCollapsed) {
          this.isSidebarCollapsed = false;
          this.applySidebarState(false);
        }
      });
    }
  }

  applySidebarState(collapsed) {
    const sidebar = document.getElementById('main-sidebar');
    const toggleBtn = document.getElementById('btn-toggle-sidebar');
    if (sidebar) {
      if (collapsed) {
        sidebar.classList.add('collapsed');
        if (toggleBtn) toggleBtn.title = 'Buka Sidebar';
      } else {
        sidebar.classList.remove('collapsed');
        if (toggleBtn) toggleBtn.title = 'Sembunyikan Sidebar';
      }
      localStorage.setItem('terrapoint_sidebar_collapsed', String(collapsed));

      if (this.mapService && this.mapService.map) {
        setTimeout(() => this.mapService.map.invalidateSize(), 250);
      }
    }
  }

  setupThemeToggle() {
    const btn = document.getElementById('btn-theme-toggle');
    if (btn) {
      btn.addEventListener('click', () => {
        const newTheme = this.currentTheme === 'DARK' ? 'LIGHT' : 'DARK';
        this.applyTheme(newTheme);
      });
    }
  }

  applyTheme(theme) {
    this.currentTheme = theme;
    localStorage.setItem('terrapoint_theme', theme);

    if (theme === 'LIGHT') {
      document.body.classList.add('light-theme');
    } else {
      document.body.classList.remove('light-theme');
    }

    const iconToggle = document.getElementById('icon-theme-toggle');
    if (iconToggle) {
      iconToggle.innerHTML = theme === 'DARK' ? Icons.sun(18) : Icons.moon(18);
    }

    if (this.mapService) {
      this.mapService.setTheme(theme);
    }
  }

  setupUserDropdownAndLogin() {
    const userProfileBtn = document.getElementById('btn-user-profile');
    const userDropdown = document.getElementById('user-dropdown-menu');
    const logoutBtn = document.getElementById('btn-dropdown-logout');
    const loginPage = document.getElementById('page-login');
    const loginForm = document.getElementById('dedicated-login-form');
    const labelUserName = document.getElementById('label-user-name');
    const dropdownUserName = document.getElementById('dropdown-user-name');
    const roleEl = document.getElementById('dropdown-user-role');

    const applyUserIdentity = (identifier) => {
      const isNoc = identifier.toLowerCase().includes('noc');
      const navLiSettings = document.getElementById('nav-li-settings');
      const navLiScreenshots = document.getElementById('nav-li-screenshots');

      if (isNoc) {
        this.currentUser = {
          name: 'Superadmin NOC',
          email: 'noc.admin@terrapoint.id',
          role: 'Infrastruktur Data Center & Server'
        };
        if (navLiSettings) navLiSettings.style.display = 'block';
        if (navLiScreenshots) navLiScreenshots.style.display = 'block';
      } else {
        this.currentUser = {
          name: 'Ahmad Fauzi',
          email: 'ahmad.fauzi@terrapoint.id',
          role: 'Head Mine Dispatcher'
        };
        if (navLiSettings) navLiSettings.style.display = 'none';
        if (navLiScreenshots) navLiScreenshots.style.display = 'none';
      }

      if (labelUserName) labelUserName.textContent = this.currentUser.name;
      if (dropdownUserName) dropdownUserName.textContent = this.currentUser.name;
      if (roleEl) roleEl.textContent = this.currentUser.role;
    };

    if (userProfileBtn && userDropdown) {
      userProfileBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        userDropdown.classList.toggle('active');
      });
      document.addEventListener('click', (e) => {
        if (!userProfileBtn.contains(e.target) && !userDropdown.contains(e.target)) {
          userDropdown.classList.remove('active');
        }
      });
    }

    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => {
        if (userDropdown) userDropdown.classList.remove('active');
        this.isLoggedIn = false;
        localStorage.removeItem('terrapoint_auth_user');
        if (loginPage) {
          loginPage.classList.add('active');
          loginPage.style.display = 'flex';
        }
      });
    }

    const chipDispatcher = document.getElementById('chip-dispatcher');
    const chipNoc = document.getElementById('chip-noc');
    const inputUser = document.getElementById('input-login-username');
    const inputPass = document.getElementById('input-login-password');

    if (chipDispatcher && inputUser) {
      chipDispatcher.addEventListener('click', () => {
        chipDispatcher.classList.add('active');
        if (chipNoc) chipNoc.classList.remove('active');
        inputUser.value = 'ahmad.fauzi@terrapoint.id';
        if (inputPass) inputPass.value = 'admin123456';
      });
    }

    if (chipNoc && inputUser) {
      chipNoc.addEventListener('click', () => {
        chipNoc.classList.add('active');
        if (chipDispatcher) chipDispatcher.classList.remove('active');
        inputUser.value = 'nocadmin@terrapoint.noc';
        if (inputPass) inputPass.value = 'P9x_NocData2026_Secure';
      });
    }

    const submitLogin = () => {
      const u = inputUser ? inputUser.value.trim() : 'ahmad.fauzi@terrapoint.id';
      applyUserIdentity(u);
      this.isLoggedIn = true;
      localStorage.setItem('terrapoint_auth_user', u);
      if (loginPage) {
        loginPage.classList.remove('active');
        loginPage.style.display = 'none';
      }
    };

    const submitBtn = document.getElementById('btn-dedicated-login-submit');
    if (submitBtn) submitBtn.addEventListener('click', submitLogin);
    if (loginForm) loginForm.addEventListener('submit', (e) => {
      e.preventDefault();
      submitLogin();
    });

    // Check saved session in localStorage, or auto-dismiss modal
    const savedUser = localStorage.getItem('terrapoint_auth_user');
    if (savedUser) {
      applyUserIdentity(savedUser);
      this.isLoggedIn = true;
      if (loginPage) {
        loginPage.classList.remove('active');
        loginPage.style.display = 'none';
      }
    } else {
      applyUserIdentity('ahmad.fauzi@terrapoint.id');
      // If user has not logged out explicitly, let them enter directly
      if (loginPage) {
        loginPage.classList.remove('active');
        loginPage.style.display = 'none';
      }
    }
  }

  setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item[data-page]');
    const views = document.querySelectorAll('.dashboard-view');

    navItems.forEach(item => {
      item.addEventListener('click', () => {
        const targetPage = item.dataset.page;
        if (!targetPage) return;

        navItems.forEach(n => n.classList.remove('active'));
        item.classList.add('active');

        views.forEach(v => {
          if (v.id === targetPage) {
            v.classList.add('active');
            v.style.display = (targetPage === 'page-live-map') ? 'flex' : 'block';
          } else {
            v.classList.remove('active');
            v.style.display = 'none';
          }
        });

        this.currentPage = targetPage;
        if (targetPage === 'page-live-map' && this.mapService && this.mapService.map) {
          setTimeout(() => this.mapService.map.invalidateSize(), 200);
        }
      });
    });
  }

  // ==========================================
  // PAGE 1: LIVE MAP & WHEEL KPI
  // ==========================================
  setupPage1LiveMap() {
    this.mapService.initMap(DEFAULT_SITE_CENTER);
    this.mapService.renderLocations(this.locations);
    this.mapService.renderLiveFleet(this.fleet);
    this.mapService.setTheme(this.currentTheme);

    this.mapService.onTruckSelectedCallback = (truck) => {
      this.showVehicleTelemetryHUD(truck);
    };

    this.renderLiveFleetPanel();
  }

  setupMapToolbarAndHUD() {
    const btnSat = document.getElementById('btn-layer-sat');
    const btnGis = document.getElementById('btn-layer-gis');
    const btnFit = document.getElementById('btn-map-fit');
    const hudDrawer = document.getElementById('telemetry-hud-drawer');
    const hudCloseBtn = document.getElementById('hud-close-btn');

    if (btnSat) {
      btnSat.addEventListener('click', () => {
        this.mapService.applyTileLayer('SATELLITE');
        btnSat.classList.add('active');
        if (btnGis) btnGis.classList.remove('active');
      });
    }

    if (btnGis) {
      btnGis.addEventListener('click', () => {
        this.mapService.applyTileLayer('GIS_DARK');
        btnGis.classList.add('active');
        if (btnSat) btnSat.classList.remove('active');
      });
    }

    if (btnFit) {
      btnFit.addEventListener('click', () => {
        if (this.mapService && this.mapService.map) {
          this.mapService.map.setView(DEFAULT_SITE_CENTER, 13);
        }
      });
    }

    if (hudCloseBtn && hudDrawer) {
      hudCloseBtn.addEventListener('click', () => {
        hudDrawer.classList.remove('active');
      });
    }
  }

  showVehicleTelemetryHUD(truck) {
    const hud = document.getElementById('telemetry-hud-drawer');
    if (!hud) return;
    document.getElementById('hud-unit-title').textContent = `UNIT ${truck.unit_id} (${truck.model})`;
    document.getElementById('hud-driver-name').textContent = `${truck.driver_name} (${truck.driver_nik})`;
    document.getElementById('hud-payload-val').textContent = `${truck.payload_ton}T (${truck.material_type})`;
    document.getElementById('hud-speed-val').textContent = `${truck.speed_kmh} km/h • Elev: +${truck.elevation_msl}m RL`;
    document.getElementById('hud-fuel-val').textContent = `${truck.fuel_level_pct}% (${truck.fuel_burn_rate_lph} L/h)`;
    document.getElementById('hud-health-val').textContent = `${truck.engine_temp_c}°C • ${truck.tire_pressure_psi} PSI`;

    hud.classList.add('active');

    if (this.mapService && this.mapService.map) {
      this.mapService.map.panTo([truck.current_lat, truck.current_lng]);
    }
  }

  renderWheelKPIs(summary) {
    // 1. Total Trips
    const totalEl = document.getElementById('kpi-total-trips');
    if (totalEl) totalEl.textContent = `${summary.total_trips_today || 0} Trip`;

    // 2. Breakdown per wheel type
    const wheels = summary.wheels_summary || [];
    const getCount = (keyword) => {
      const match = wheels.find(w => w.wheel_type && w.wheel_type.toLowerCase().includes(keyword));
      return match ? parseInt(match.trip_count, 10) : 0;
    };

    const count6 = getCount('6 roda') || getCount('dump');
    const count10 = getCount('10 roda') || getCount('tronton');
    const count12 = getCount('12 roda') || getCount('trailer');

    const el6 = document.getElementById('kpi-wheel-6');
    if (el6) el6.textContent = `${count6} Trip`;

    const el10 = document.getElementById('kpi-wheel-10');
    if (el10) el10.textContent = `${count10} Trip`;

    const el12 = document.getElementById('kpi-wheel-12');
    if (el12) el12.textContent = `${count12} Trip`;
  }

  renderLiveFleetPanel() {
    const container = document.getElementById('fleet-list');
    if (!container) return;
    container.innerHTML = this.fleet.map(truck => {
      const c = this.mapService?.getDriverColor?.(truck.driver_id || truck.driver_name) || { border: '#3B82F6', text: '#60A5FA', bg: 'rgba(59, 130, 246, 0.2)' };
      return `
        <div class="fleet-card" data-unit="${truck.unit_id}" style="border-left: 3.5px solid ${c.border};">
          <div class="fleet-card-header">
            <span class="unit-tag" style="background: ${c.bg}; color: ${c.text}; border: 1px solid ${c.border};">${truck.unit_id} [${truck.model}]</span>
            <span class="speed-tag">${truck.speed_kmh > 0 ? `${truck.speed_kmh} km/h` : 'STASIONER'}</span>
          </div>
          <div class="fleet-route">${truck.haul_cycle_stage || 'Siap Tugas'}</div>
          <div class="fleet-driver" style="font-weight: 600;"><span style="color: ${c.text};">●</span> ${truck.driver_name} • ${truck.fuel_level_pct}% BBM</div>
        </div>
      `;
    }).join('');

    container.querySelectorAll('.fleet-card').forEach(card => {
      card.addEventListener('click', () => {
        const truck = this.fleet.find(f => f.unit_id === card.dataset.unit);
        if (truck) this.showVehicleTelemetryHUD(truck);
      });
    });
  }

  renderLiveMapTripsTable(tripsList) {
    const tbody = document.getElementById('live-map-table-body');
    if (!tbody) return;
    if (!tripsList || tripsList.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 28px; color: var(--text-muted);">Belum ada pengantaran hari ini. Pengemudi yang melakukan muatan di Pit akan otomatis tercatat di sini.</td></tr>';
      return;
    }

    tbody.innerHTML = tripsList.slice(0, 6).map(trip => {
      const isCompleted = trip.status === 'COMPLETED';
      return `
        <tr data-trip-id="${trip.trip_id}" style="cursor: pointer;">
          <td style="white-space: nowrap;">
            <span class="mono-id-badge">${trip.trip_id}</span>
          </td>
          <td>
            <div class="cell-primary">${trip.driver_name || 'Pengemudi'}</div>
            <div class="cell-sub mono" style="color: var(--accent-primary); font-weight: 600;">${trip.truck_wheel_type || '6 Roda'}</div>
          </td>
          <td>
            <div class="cell-primary">${trip.project_name || 'Proyek Hauling'}</div>
          </td>
          <td>
            <div class="cell-primary">${trip.start_point_name || 'Titik Muat Pit'}</div>
            <div class="cell-sub" style="color: var(--status-success);">Radius Luas ±${trip.load_deviation_m || 12}m</div>
          </td>
          <td>
            <div class="cell-primary">${trip.end_point_name || 'ROM Stockpile'}</div>
            <div class="cell-sub" style="color: var(--status-info);">1 Titik Bongkar Spesifik</div>
          </td>
          <td>
            <span class="status-badge ${isCompleted ? 'completed' : 'in_progress'}">
              <span class="status-dot"></span>
              <span>${isCompleted ? 'Selesai' : 'Dalam Perjalanan'}</span>
            </span>
          </td>
          <td style="text-align: right; white-space: nowrap;">
            <button class="btn-action secondary btn-open-trip-evidence" data-trip-id="${trip.trip_id}" style="height: 30px; padding: 0 10px; font-size: 11.5px;">
              ${Icons.camera(13)}
              <span>Bukti Nota & Foto</span>
            </button>
          </td>
        </tr>
      `;
    }).join('');

    tbody.querySelectorAll('.btn-open-trip-evidence').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.openEvidenceModal(btn.dataset.tripId);
      });
    });
  }

  // ==========================================
  // PAGE 2: LOG PENGANTARAN & MASTER GEOFENCE
  // ==========================================
  setupPage2TripLogs() {
    const btnTabLogs = document.getElementById('subtab-btn-logs');
    const btnTabGeo = document.getElementById('subtab-btn-geofence');
    const viewLogs = document.getElementById('subview-logs');
    const viewGeo = document.getElementById('subview-geofence');

    if (btnTabLogs && btnTabGeo && viewLogs && viewGeo) {
      btnTabLogs.addEventListener('click', () => {
        btnTabLogs.classList.add('active');
        btnTabGeo.classList.remove('active');
        viewLogs.style.display = 'block';
        viewGeo.style.display = 'none';
      });
      btnTabGeo.addEventListener('click', () => {
        btnTabGeo.classList.add('active');
        btnTabLogs.classList.remove('active');
        viewGeo.style.display = 'block';
        viewLogs.style.display = 'none';
      });
    }

    const searchInput = document.getElementById('input-search-logs');
    const statusFilter = document.getElementById('filter-status-logs');
    const exportBtn = document.getElementById('btn-export-csv');

    const updateLogs = () => {
      const query = searchInput ? searchInput.value.toLowerCase().trim() : '';
      const status = statusFilter ? statusFilter.value : 'ALL';

      const filtered = this.trips.filter(t => {
        const matchQ = (t.trip_id || '').toLowerCase().includes(query) ||
                       (t.driver_name || '').toLowerCase().includes(query) ||
                       (t.truck_wheel_type || '').toLowerCase().includes(query) ||
                       (t.project_name || '').toLowerCase().includes(query);
        const matchStatus = (status === 'ALL') || (t.status === status);
        return matchQ && matchStatus;
      });

      this.renderTripLogsTable(filtered);
    };

    if (searchInput) searchInput.addEventListener('input', updateLogs);
    if (statusFilter) statusFilter.addEventListener('change', updateLogs);
    if (exportBtn) exportBtn.addEventListener('click', () => this.exportTripsToCSV());

    this.renderTripLogsTable(this.trips);
  }

  renderTripLogsTable(tripsList) {
    const tbody = document.getElementById('trip-logs-table-body');
    if (!tbody) return;
    if (!tripsList || tripsList.length === 0) {
      tbody.innerHTML = `<tr><td colspan="8" style="text-align: center; color: var(--text-muted); padding: 32px;">Belum ada riwayat pengantaran yang sesuai filter.</td></tr>`;
      return;
    }

    tbody.innerHTML = tripsList.map(t => {
      const isCompleted = t.status === 'COMPLETED';
      const timeStr = t.load_at ? new Date(t.load_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '08:00';
      return `
        <tr data-trip-id="${t.trip_id}">
          <td style="white-space: nowrap;">
            <div class="mono-id-badge">${t.trip_id}</div>
            <div class="cell-sub mono" style="margin-top: 3px;">Pukul ${timeStr} WITA</div>
          </td>
          <td>
            <div class="cell-primary">${t.driver_name}</div>
            <div class="cell-sub mono" style="color: var(--accent-primary); font-weight: 600;">${t.truck_wheel_type || '6 Roda'}</div>
          </td>
          <td>
            <div class="cell-primary">${t.project_name}</div>
            <div class="cell-sub">Trip #${t.trip_sequence || 1}</div>
          </td>
          <td>
            ${t.load_photo_url ? `
              <span class="status-badge completed" style="font-size: 11px;">✓ Foto Muat Pit</span>
            ` : `<span class="cell-sub" style="color: var(--status-error);">Belum Ada</span>`}
          </td>
          <td>
            ${t.dump_photo_url ? `
              <span class="status-badge completed" style="font-size: 11px;">✓ Foto Bongkar ROM</span>
            ` : `<span class="cell-sub" style="color: var(--text-muted);">Menunggu Selesai</span>`}
          </td>
          <td>
            ${t.invoice_photo_url ? `
              <span class="status-badge" style="background: rgba(59, 130, 246, 0.15); color: #60A5FA; border: 1px solid rgba(59, 130, 246, 0.3); font-size: 11px; font-weight: 600;">✓ Ada Nota Timbang</span>
            ` : `<span class="cell-sub" style="color: var(--text-muted);">Belum Upload</span>`}
          </td>
          <td>
            <span class="status-badge ${isCompleted ? 'completed' : 'in_progress'}">
              <span class="status-dot"></span>
              <span>${isCompleted ? 'Terverifikasi' : 'Dalam Perjalanan'}</span>
            </span>
          </td>
          <td style="text-align: right; white-space: nowrap;">
            <button class="btn-action secondary btn-open-trip-evidence" data-trip-id="${t.trip_id}" style="height: 30px; padding: 0 11px; font-size: 12px;">
              ${Icons.camera(13)}
              <span>Bukti</span>
            </button>
          </td>
        </tr>
      `;
    }).join('');

    tbody.querySelectorAll('.btn-open-trip-evidence').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.openEvidenceModal(btn.dataset.tripId);
      });
    });
  }

  exportTripsToCSV() {
    const headers = ['Trip ID', 'Driver', 'Jenis Roda Truk', 'Proyek Hauling', 'Titik Muat', 'Titik Bongkar', 'Status', 'Foto Muat', 'Foto Bongkar', 'Foto Nota', 'Waktu'];
    const rows = this.trips.map(t => [
      t.trip_id,
      `"${t.driver_name}"`,
      `"${t.truck_wheel_type}"`,
      `"${t.project_name}"`,
      `"${t.start_point_name || ''}"`,
      `"${t.end_point_name || ''}"`,
      t.status,
      t.load_photo_url ? 'YES' : 'NO',
      t.dump_photo_url ? 'YES' : 'NO',
      t.invoice_photo_url ? 'YES' : 'NO',
      t.created_at
    ]);

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map(e => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `terrapoint_trips_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  // ==========================================
  // PAGE 3: MANAJEMEN PROYEK HAULING (TASK PER PROYEK)
  // ==========================================
  setupProjectsAndTrips() {
    const searchInput = document.getElementById('input-search-tasks');
    const filterStatus = document.getElementById('filter-status-tasks');

    const updateProjects = () => {
      const q = searchInput ? searchInput.value.toLowerCase().trim() : '';
      const status = filterStatus ? filterStatus.value : 'ALL';
      const filtered = this.projects.filter(p => {
        const matchQ = (p.project_name || '').toLowerCase().includes(q) ||
                       (p.client_name || '').toLowerCase().includes(q) ||
                       (p.start_point_name || '').toLowerCase().includes(q) ||
                       (p.end_point_name || '').toLowerCase().includes(q);
        const matchStatus = (status === 'ALL') || (status === 'ACTIVE' && p.is_active) || (status === 'INACTIVE' && !p.is_active);
        return matchQ && matchStatus;
      });
      this.renderProjectsTable(filtered);
    };

    if (searchInput) searchInput.addEventListener('input', updateProjects);
    if (filterStatus) filterStatus.addEventListener('change', updateProjects);

    // Modal Create Project
    const modal = document.getElementById('assign-task-modal');
    const btnOpenTop = document.getElementById('btn-top-assign-task');
    const btnOpenPage = document.getElementById('btn-assign-task-open');
    const btnClose = document.getElementById('modal-assign-task-close');
    const btnCancel = document.getElementById('btn-cancel-assign-task');
    const btnSubmit = document.getElementById('btn-submit-assign-task');

    const openModal = () => {
      this.populateLocationDropdowns(this.locations);
      if (modal) modal.classList.add('active');
    };

    if (btnOpenTop) btnOpenTop.addEventListener('click', openModal);
    if (btnOpenPage) btnOpenPage.addEventListener('click', openModal);
    if (btnClose) btnClose.addEventListener('click', () => modal.classList.remove('active'));
    if (btnCancel) btnCancel.addEventListener('click', () => modal.classList.remove('active'));

    // Dynamic Radius Slider synchronization in Project Modal
    const startRadInput = document.getElementById('input-start-radius');
    const startRadBadge = document.getElementById('badge-start-radius');
    if (startRadInput && startRadBadge) {
      startRadInput.addEventListener('input', () => {
        startRadBadge.textContent = `${startRadInput.value} meter`;
      });
    }

    const endRadInput = document.getElementById('input-end-radius');
    const endRadBadge = document.getElementById('badge-end-radius');
    if (endRadInput && endRadBadge) {
      endRadInput.addEventListener('input', () => {
        endRadBadge.textContent = `${endRadInput.value} meter`;
      });
    }

    if (btnSubmit) {
      btnSubmit.addEventListener('click', async () => {
        const name = document.getElementById('project-input-name')?.value;
        const client = document.getElementById('project-input-client')?.value;
        const startLocId = document.getElementById('assign-select-start-loc')?.value;
        const startRad = parseInt(document.getElementById('input-start-radius')?.value || 250, 10);
        const endLocId = document.getElementById('assign-select-end-loc')?.value;
        const endRad = parseInt(document.getElementById('input-end-radius')?.value || 40, 10);

        if (!name || !startLocId || !endLocId) {
          alert('Mohon isi nama proyek, titik muat, dan titik bongkar.');
          return;
        }

        try {
          const resp = await fetch('/api/dashboard/projects', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              project_name: name,
              client_name: client,
              start_location_id: startLocId,
              start_radius_meters: startRad,
              end_location_id: endLocId,
              end_radius_meters: endRad
            })
          });
          const data = await resp.json();
          if (data && data.success) {
            modal.classList.remove('active');
            await this.fetchLiveBackendData();
            alert(`✅ ${data.message || 'Proyek Hauling baru berhasil dibuat!'}`);
          } else {
            alert(`⚠️ Gagal membuat proyek: ${data.error || 'Terjadi kesalahan'}`);
          }
        } catch (err) {
          alert(`❌ Gagal menghubungi server: ${err.message}`);
        }
      });
    }

    this.renderProjectsTable(this.projects);
  }

  renderProjectsTable(projectsList) {
    const tbody = document.getElementById('tasks-table-body');
    if (!tbody) return;

    if (!projectsList || projectsList.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 32px;">Belum ada proyek hauling terdaftar. Klik tombol "+ Buat Proyek Hauling Baru" untuk membuat proyek.</td></tr>';
      return;
    }

    tbody.innerHTML = projectsList.map(p => {
      const driversList = p.assigned_drivers || [];
      const driversHtml = driversList.length > 0
        ? driversList.map(d => `<span class="mono-id-badge" style="font-size: 11px; margin: 2px 4px 2px 0;">${d.full_name} (${d.truck_wheel_type?.split(' ')[0] || '6 Roda'})</span>`).join('')
        : '<span class="cell-sub">Belum ada driver assigned</span>';

      return `
        <tr data-project-id="${p.project_id}">
          <td style="white-space: nowrap;">
            <div class="mono-id-badge">${p.project_id}</div>
          </td>
          <td>
            <div class="cell-primary">${p.project_name}</div>
            <div class="cell-sub">${p.client_name}</div>
          </td>
          <td>
            <div class="cell-primary">${p.start_point_name}</div>
            <div class="cell-sub" style="color: var(--accent-primary); font-family: var(--font-mono); font-weight: 600;">Radius Luas: ${p.start_radius_meters || 250} meter</div>
          </td>
          <td>
            <div class="cell-primary">${p.end_point_name}</div>
            <div class="cell-sub" style="color: var(--status-success); font-family: var(--font-mono); font-weight: 600;">1 Titik Ketat: ${p.end_radius_meters || 40} meter</div>
          </td>
          <td>
            <div style="display: flex; flex-wrap: wrap; max-width: 280px;">${driversHtml}</div>
          </td>
          <td style="white-space: nowrap;">
            <div class="cell-primary" style="font-weight: 700; color: var(--status-success);">${p.today_completed_trips || 0} Trip Selesai</div>
            <div class="cell-sub">${p.in_transit_trips || 0} Sedang Berjalan</div>
          </td>
          <td style="text-align: right; white-space: nowrap;">
            <button class="btn-action secondary" style="height: 30px; padding: 0 11px; font-size: 11.5px;" onclick="window.dispatcherApp.editProjectRadius('${p.project_id}', ${p.start_radius_meters || 250}, ${p.end_radius_meters || 40})">
              ${Icons.edit(12)}
              <span>Ubah Radius</span>
            </button>
          </td>
        </tr>
      `;
    }).join('');
  }

  async editProjectRadius(projectId, currentStartRad, currentEndRad) {
    const newStart = prompt(`Ubah Radius Titik Muat (Luas, 100 - 600 meter):`, currentStartRad);
    if (!newStart) return;
    const newEnd = prompt(`Ubah Radius Titik Bongkar (Ketat, 20 - 100 meter):`, currentEndRad);
    if (!newEnd) return;

    try {
      const res = await fetch(`/api/dashboard/projects/${projectId}/radius`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          start_radius_meters: parseInt(newStart, 10),
          end_radius_meters: parseInt(newEnd, 10)
        })
      });
      const data = await res.json();
      if (data && data.success) {
        await this.fetchLiveBackendData();
        alert(`✅ Radius Proyek berhasil diperbarui! (Muat: ${newStart}m, Bongkar: ${newEnd}m)`);
      } else {
        alert(`⚠️ Gagal mengubah radius: ${data.error || 'Terjadi kesalahan'}`);
      }
    } catch (e) {
      alert(`❌ Error: ${e.message}`);
    }
  }

  // ==========================================
  // PAGE 4: DAFTAR DRIVER & JENIS RODA TRUK
  // ==========================================
  setupDriversManagement() {
    const searchInput = document.getElementById('input-search-drivers');
    const filterStatus = document.getElementById('filter-driver-status');

    const updateTable = () => {
      const q = searchInput ? searchInput.value.toLowerCase().trim() : '';
      const status = filterStatus ? filterStatus.value : 'ALL';
      const filtered = this.drivers.filter(d => {
        const matchQ = (d.full_name || '').toLowerCase().includes(q) ||
                       (d.driver_id || '').toLowerCase().includes(q) ||
                       (d.truck_wheel_type || '').toLowerCase().includes(q);
        const matchStatus = (status === 'ALL') ||
                            (status === 'ACTIVE' && d.is_active) ||
                            (status === 'INACTIVE' && !d.is_active);
        return matchQ && matchStatus;
      });
      this.renderDriversTable(filtered);
    };

    if (searchInput) searchInput.addEventListener('input', updateTable);
    if (filterStatus) filterStatus.addEventListener('change', updateTable);

    // Modal Add Driver
    const modal = document.getElementById('add-driver-modal');
    const btnOpen = document.getElementById('btn-add-driver-modal-open');
    const btnClose = document.getElementById('modal-add-driver-close');
    const btnCancel = document.getElementById('btn-cancel-add-driver');
    const btnSubmit = document.getElementById('btn-submit-add-driver');

    if (btnOpen) {
      btnOpen.addEventListener('click', () => {
        this.populateProjectDropdowns(this.projects);
        if (modal) modal.classList.add('active');
      });
    }
    if (btnClose) btnClose.addEventListener('click', () => modal.classList.remove('active'));
    if (btnCancel) btnCancel.addEventListener('click', () => modal.classList.remove('active'));

    if (btnSubmit) {
      btnSubmit.addEventListener('click', async () => {
        const driverId = document.getElementById('driver-input-id')?.value;
        const fullName = document.getElementById('driver-input-name')?.value;
        const phone = document.getElementById('driver-input-phone')?.value;
        const wheel = document.getElementById('driver-select-wheel')?.value;
        const projectId = document.getElementById('driver-select-project')?.value;
        const pin = document.getElementById('driver-input-pin')?.value || '123456';

        if (!driverId || !fullName || !phone) {
          alert('Mohon lengkapi ID Driver, Nama Lengkap, dan Nomor Telepon.');
          return;
        }

        try {
          const resp = await fetch('/api/dashboard/drivers', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              driver_id: driverId,
              full_name: fullName,
              phone_number: phone,
              truck_wheel_type: wheel,
              assigned_project_id: projectId,
              pin
            })
          });
          const data = await resp.json();
          if (data && data.success) {
            modal.classList.remove('active');
            await this.fetchLiveBackendData();
            alert(`✅ Driver ${fullName} berhasil didaftarkan!`);
          } else {
            alert(`⚠️ Gagal mendaftarkan driver: ${data.error || 'Terjadi kesalahan'}`);
          }
        } catch (err) {
          alert(`❌ Gagal menghubungi server: ${err.message}`);
        }
      });
    }

    this.renderDriversTable(this.drivers);
  }

  renderDriversTable(driversList) {
    const tbody = document.getElementById('drivers-table-body');
    if (!tbody) return;

    if (!driversList || driversList.length === 0) {
      tbody.innerHTML = '<tr><td colspan="9" style="text-align: center; color: var(--text-muted); padding: 28px;">Belum ada data driver. Klik tombol "+ Daftarkan Driver Baru" untuk menambahkan pengemudi.</td></tr>';
      return;
    }

    tbody.innerHTML = driversList.map(d => {
      return `
        <tr>
          <td style="white-space: nowrap;">
            <span class="mono-id-badge">${d.driver_id}</span>
          </td>
          <td>
            <div class="cell-primary">${d.full_name}</div>
          </td>
          <td style="font-family: var(--font-sans); color: var(--text-secondary);">${d.phone_number || '—'}</td>
          <td style="white-space: nowrap;">
            <span class="mono-id-badge" style="background: rgba(245, 158, 11, 0.15); color: #F59E0B; border: 1px solid rgba(245, 158, 11, 0.3); font-weight: 600;">
              ${d.truck_wheel_type || '6 Roda (Dump Truck)'}
            </span>
          </td>
          <td>
            <div class="cell-primary">${d.assigned_project_name || 'Proyek Hauling Utama'}</div>
          </td>
          <td>
            <span class="status-badge ${d.is_active ? 'completed' : 'standby'}">
              <span class="status-dot"></span>
              <span>${d.is_active ? 'Aktif (Bisa Login)' : 'Nonaktif (Diblokir)'}</span>
            </span>
          </td>
          <td style="white-space: nowrap;">
            ${d.is_active ? `
              <button class="btn-action secondary" style="height: 28px; padding: 0 10px; font-size: 11px; color: var(--status-error); border-color: rgba(239, 68, 68, 0.35);" title="Blokir akses login driver" onclick="window.dispatcherApp.toggleDriverActive('${d.driver_id}')">
                Nonaktifkan
              </button>
            ` : `
              <button class="btn-action" style="height: 28px; padding: 0 12px; font-size: 11px; background: var(--status-success);" title="Buka akses login driver" onclick="window.dispatcherApp.toggleDriverActive('${d.driver_id}')">
                Aktifkan
              </button>
            `}
          </td>
          <td style="font-family: var(--font-mono); font-weight: 700; font-size: 13px; color: var(--status-success); white-space: nowrap;">
            ${d.today_trips_count || 0} Trip
          </td>
          <td style="text-align: right; white-space: nowrap;">
            <button class="btn-action secondary" style="height: 28px; padding: 0 10px; font-size: 11.5px;" onclick="window.dispatcherApp.promptEditDriverWheel('${d.driver_id}', '${d.truck_wheel_type || '6 Roda (Dump Truck)'}')">
              ${Icons.edit(12)}
              <span>Ubah Roda</span>
            </button>
          </td>
        </tr>
      `;
    }).join('');
  }

  async toggleDriverActive(driverId) {
    try {
      const res = await fetch(`/api/dashboard/drivers/${driverId}/toggle`, { method: 'PUT' });
      if (res.ok) {
        await this.fetchLiveBackendData();
        return;
      }
    } catch (e) {
      console.warn('Driver toggle notice:', e);
    }
  }

  async promptEditDriverWheel(driverId, currentWheel) {
    const wheelOptions = ['4 Roda (Pick-up / Engkel)', '6 Roda (Dump Truck)', '10 Roda (Tronton)', '12 Roda (Trailer Heavy)'];
    const choice = prompt(`Pilih jenis roda mobil untuk driver ${driverId}:\n1. 4 Roda (Pick-up)\n2. 6 Roda (Dump Truck)\n3. 10 Roda (Tronton)\n4. 12 Roda (Trailer Heavy)\n\nKetik angka 1, 2, 3, atau 4:`, '2');
    if (!choice) return;

    let selectedWheel = currentWheel;
    if (choice === '1') selectedWheel = '4 Roda (Pick-up / Engkel)';
    else if (choice === '2') selectedWheel = '6 Roda (Dump Truck)';
    else if (choice === '3') selectedWheel = '10 Roda (Tronton)';
    else if (choice === '4') selectedWheel = '12 Roda (Trailer Heavy)';

    try {
      const res = await fetch(`/api/dashboard/drivers/${driverId}/assign-project`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ truck_wheel_type: selectedWheel })
      });
      const data = await res.json();
      if (data && data.success) {
        await this.fetchLiveBackendData();
        alert(`✅ Jenis roda driver berhasil diubah menjadi: ${selectedWheel}`);
      }
    } catch (e) {
      alert(`❌ Error: ${e.message}`);
    }
  }

  // ==========================================
  // MASTER GEOFENCE (TITIK MUAT & TITIK BONGKAR DINAMIS)
  // ==========================================
  setupPage3Geofence() {
    const modal = document.getElementById('checkpoint-modal');
    const openBtn = document.getElementById('btn-add-checkpoint');
    const closeBtn = document.getElementById('checkpoint-modal-close');
    const cancelBtn = document.getElementById('btn-cancel-checkpoint');
    const saveBtn = document.getElementById('btn-save-new-checkpoint');
    const searchInput = document.getElementById('input-search-geofence');

    if (openBtn) openBtn.addEventListener('click', () => modal.classList.add('active'));
    if (closeBtn) closeBtn.addEventListener('click', () => modal.classList.remove('active'));
    if (cancelBtn) cancelBtn.addEventListener('click', () => modal.classList.remove('active'));

    const radiusInput = document.getElementById('input-checkpoint-radius');
    const radiusBadge = document.getElementById('badge-checkpoint-modal-radius');
    if (radiusInput && radiusBadge) {
      radiusInput.addEventListener('input', () => {
        radiusBadge.textContent = `${radiusInput.value}m`;
      });
    }

    if (saveBtn) {
      saveBtn.addEventListener('click', async () => {
        const name = document.getElementById('input-checkpoint-name')?.value;
        const type = document.getElementById('select-checkpoint-type')?.value;
        const lat = parseFloat(document.getElementById('input-checkpoint-lat')?.value);
        const lng = parseFloat(document.getElementById('input-checkpoint-lng')?.value);
        const radius = parseInt(document.getElementById('input-checkpoint-radius')?.value || 50, 10);

        if (!name || isNaN(lat) || isNaN(lng)) {
          alert('Mohon lengkapi nama titik dan koordinat GPS.');
          return;
        }

        try {
          const resp = await fetch('/api/dashboard/geofences', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              name,
              location_type: type,
              latitude: lat,
              longitude: lng,
              radius_meters: radius
            })
          });
          const data = await resp.json();
          if (data && data.success) {
            modal.classList.remove('active');
            await this.fetchLiveBackendData();
            alert(`✅ Titik ${name} berhasil ditambahkan!`);
          }
        } catch (e) {
          alert(`❌ Error: ${e.message}`);
        }
      });
    }

    if (searchInput) {
      searchInput.addEventListener('input', () => {
        const q = searchInput.value.toLowerCase().trim();
        const filtered = this.locations.filter(l => (l.name || '').toLowerCase().includes(q));
        this.renderGeofenceTable(filtered);
      });
    }

    this.renderGeofenceTable(this.locations);
  }

  renderGeofenceTable(locationsList) {
    const tbody = document.getElementById('geofence-table-body');
    if (!tbody) return;
    tbody.innerHTML = locationsList.map(loc => `
      <tr>
        <td style="white-space: nowrap;">
          <span class="mono-id-badge">${(loc.code || loc.location_id).slice(0, 12)}</span>
        </td>
        <td>
          <div class="cell-primary">${loc.name}</div>
        </td>
        <td style="white-space: nowrap;">
          <span class="status-badge ${loc.type === 'LOADING_POINT' ? 'in_progress' : 'completed'}">
            <span class="status-dot"></span>
            <span>${loc.type === 'LOADING_POINT' ? 'Titik Muat (Radius Luas)' : 'Titik Bongkar (Radius Ketat)'}</span>
          </span>
        </td>
        <td style="white-space: nowrap;">
          <div class="cell-primary mono">${(loc.lat || 0).toFixed(5)}, ${(loc.lng || 0).toFixed(5)}</div>
        </td>
        <td style="white-space: nowrap;">
          <span class="cell-primary mono" style="font-weight: 700; color: ${loc.type === 'LOADING_POINT' ? 'var(--accent-primary)' : 'var(--status-success)'};">${loc.radius || 50} meter</span>
        </td>
        <td>
          <button class="status-badge ${loc.is_active ? 'completed' : 'standby'}" style="cursor: pointer;" onclick="window.dispatcherApp.toggleGeofenceActive('${loc.location_id}')">
            <span class="status-dot"></span>
            <span>${loc.is_active ? 'Aktif' : 'Nonaktif'}</span>
          </button>
        </td>
        <td style="text-align: right; white-space: nowrap;">
          <button class="btn-action secondary" style="height: 30px; padding: 0 11px; font-size: 11.5px;" onclick="window.dispatcherApp.promptEditRadius('${loc.location_id}', ${loc.radius || 50})">
            ${Icons.edit(12)}
            <span>Radius</span>
          </button>
        </td>
      </tr>
    `).join('');
  }

  async toggleGeofenceActive(locId) {
    try {
      const res = await fetch(`/api/dashboard/geofences/${locId}/toggle`, { method: 'PUT' });
      if (res.ok) {
        await this.fetchLiveBackendData();
      }
    } catch (e) {
      console.warn('Geofence toggle notice:', e);
    }
  }

  async promptEditRadius(locId, currentRadius) {
    const newRad = prompt(`Ubah radius geofence (10 - 1000 meter):`, currentRadius);
    if (!newRad) return;
    const radNum = parseInt(newRad, 10);
    if (isNaN(radNum) || radNum < 10 || radNum > 1000) {
      alert('Radius harus berupa angka antara 10 - 1000 meter.');
      return;
    }
    try {
      const res = await fetch(`/api/dashboard/geofences/${locId}/radius`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ radius_meters: radNum })
      });
      if (res.ok) {
        await this.fetchLiveBackendData();
        alert(`✅ Radius checkpoint berhasil diubah menjadi ${radNum}m!`);
      }
    } catch (e) {
      console.warn('Radius update notice:', e);
    }
  }

  // ==========================================
  // EVIDENCE VERIFICATION MODAL (3 FOTO: MUAT, BONGKAR, NOTA)
  // ==========================================
  openEvidenceModal(identifier) {
    const trip = this.trips.find(t => t.trip_id === identifier);
    const modalTitle = document.getElementById('modal-task-title');
    const driverInfo = document.getElementById('modal-driver-info');

    let startPhoto = null;
    let endPhoto = null;
    let invoicePhoto = null;
    let startLoc = 'Loading Point Pit';
    let endLoc = 'ROM Stockpile';

    if (trip) {
      if (modalTitle) modalTitle.textContent = `Verifikasi Visual Pengantaran (${trip.trip_id})`;
      if (driverInfo) driverInfo.textContent = `Driver: ${trip.driver_name} | Jenis Roda: ${trip.truck_wheel_type || '6 Roda'} | Proyek: ${trip.project_name}`;
      startPhoto = trip.load_photo_url;
      endPhoto = trip.dump_photo_url;
      invoicePhoto = trip.invoice_photo_url;
      startLoc = trip.start_point_name || 'Titik Muat Pit';
      endLoc = trip.end_point_name || 'ROM Stockpile';
    }

    const placeholderPhoto = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="250" viewBox="0 0 400 250" fill="%23161b22"><rect width="400" height="250" fill="%23161b22"/><text x="50%" y="45%" fill="%23e58b04" font-family="monospace" font-size="13" font-weight="bold" text-anchor="middle">BUKTI VERIFIKASI VISUAL</text><text x="50%" y="60%" fill="%238b949e" font-family="sans-serif" font-size="11" text-anchor="middle">Watermark Kamera &amp; Geofence Valid</text></svg>';

    const elStartPhoto = document.getElementById('modal-start-photo');
    const elStartLoc = document.getElementById('modal-start-location');
    if (elStartPhoto) elStartPhoto.src = startPhoto || placeholderPhoto;
    if (elStartLoc) elStartLoc.textContent = startLoc;

    const elEndPhoto = document.getElementById('modal-end-photo');
    const elEndLoc = document.getElementById('modal-end-location');
    if (elEndPhoto) elEndPhoto.src = endPhoto || placeholderPhoto;
    if (elEndLoc) elEndLoc.textContent = endLoc;

    const elInvoicePhoto = document.getElementById('modal-invoice-photo');
    if (elInvoicePhoto) elInvoicePhoto.src = invoicePhoto || placeholderPhoto;

    const modal = document.getElementById('evidence-modal');
    if (modal) modal.classList.add('active');
  }

  setupEvidenceModal() {
    const modal = document.getElementById('evidence-modal');
    const closeBtn = document.getElementById('modal-close-btn');
    if (closeBtn && modal) {
      closeBtn.addEventListener('click', () => modal.classList.remove('active'));
      modal.addEventListener('click', (e) => {
        if (e.target === modal) modal.classList.remove('active');
      });
    }
  }

  // Dropdown helper functions
  populateLocationDropdowns(locations) {
    const selStart = document.getElementById('assign-select-start-loc');
    const selEnd = document.getElementById('assign-select-end-loc');

    const startLocs = locations.filter(l => l.type === 'LOADING_POINT');
    const endLocs = locations.filter(l => l.type === 'DUMPING_POINT');

    if (selStart) {
      selStart.innerHTML = (startLocs.length > 0 ? startLocs : locations).map(l => `
        <option value="${l.location_id}">${l.name} (Radius Luas)</option>
      `).join('');
    }

    if (selEnd) {
      selEnd.innerHTML = (endLocs.length > 0 ? endLocs : locations).map(l => `
        <option value="${l.location_id}">${l.name} (Radius Ketat)</option>
      `).join('');
    }
  }

  populateProjectDropdowns(projects) {
    const sel = document.getElementById('driver-select-project');
    if (sel && projects.length > 0) {
      sel.innerHTML = projects.map(p => `
        <option value="${p.project_id}">${p.project_name}</option>
      `).join('');
    }
  }

  populateDriverDropdowns(drivers) {
    // optional helper
  }

  setupPage5Settings() {
    // Admin settings helper
  }

  registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(err => {
        console.log('SW notice:', err);
      });
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const app = new DispatcherApp();
  window.dispatcherApp = app;
  app.init();
});
