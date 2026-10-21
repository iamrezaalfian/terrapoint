// Lucide & Better Auth SVG Icons Library for TerraPoint Mining Dashboard
export const Icons = {
  svg: (paths, size = 18, className = '') => `
    <svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide-icon ${className}">
      ${paths}
    </svg>
  `,

  // Better Auth Official Brand Icon
  betterAuth: (size = 20) => `
    <svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24" fill="currentColor" class="lucide-icon">
      <path d="M12.1 10.36h3.05v3.32H12.1z"/>
      <path d="M3 3v18h18V3zm15.48 10.68v3H12.1v-3H8.62v3H5.49V7.36h3.13v3h3.48v-3h6.38z"/>
    </svg>
  `,

  satellite: (size = 16) => `
    <svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide-icon">
      <path d="m3.7 6.3 2.6-2.6a1 1 0 0 1 1.4 0l5.6 5.6a1 1 0 0 1 0 1.4L10.7 13.3a1 1 0 0 1-1.4 0L3.7 7.7a1 1 0 0 1 0-1.4"/>
      <path d="m6 10-3 3 3 3 3-3"/>
      <path d="m11 5 3-3 3 3-3 3"/>
      <path d="m13 14 1.5 1.5"/>
      <path d="M17.5 19a2.5 2.5 0 0 0 2.5-2.5"/>
      <path d="M15 21a6 6 0 0 0 6-6"/>
    </svg>
  `,

  crosshair: (size = 16) => Icons.svg(`
    <circle cx="12" cy="12" r="10"></circle>
    <line x1="22" y1="12" x2="18" y2="12"></line>
    <line x1="6" y1="12" x2="2" y2="12"></line>
    <line x1="12" y1="6" x2="12" y2="2"></line>
    <line x1="12" y1="22" x2="12" y2="18"></line>
  `, size),

  panelLeft: (size = 18) => Icons.svg(`
    <rect width="18" height="18" x="3" y="3" rx="2"></rect>
    <path d="M9 3v18"></path>
  `, size),

  menu: (size = 18) => Icons.svg(`
    <line x1="4" x2="20" y1="12" y2="12"></line>
    <line x1="4" x2="20" y1="6" y2="6"></line>
    <line x1="4" x2="20" y1="18" y2="18"></line>
  `, size),

  user: (size = 16) => Icons.svg(`
    <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path>
    <circle cx="12" cy="7" r="4"></circle>
  `, size),

  sun: (size = 18) => Icons.svg(`
    <circle cx="12" cy="12" r="4"></circle>
    <line x1="12" y1="2" x2="12" y2="4"></line>
    <line x1="12" y1="20" x2="12" y2="22"></line>
    <line x1="4.93" y1="4.93" x2="6.34" y2="6.34"></line>
    <line x1="17.66" y1="17.66" x2="19.07" y2="19.07"></line>
    <line x1="2" y1="12" x2="4" y2="12"></line>
    <line x1="20" y1="12" x2="22" y2="12"></line>
    <line x1="6.34" y1="17.66" x2="4.93" y2="19.07"></line>
    <line x1="19.07" y1="4.93" x2="17.66" y2="6.34"></line>
  `, size),

  moon: (size = 18) => Icons.svg(`
    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
  `, size),

  logIn: (size = 16) => Icons.svg(`
    <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"></path>
    <polyline points="10 17 15 12 10 7"></polyline>
    <line x1="15" y1="12" x2="3" y2="12"></line>
  `, size),

  logOut: (size = 16) => Icons.svg(`
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
    <polyline points="16 17 21 12 16 7"></polyline>
    <line x1="21" y1="12" x2="9" y2="12"></line>
  `, size),

  map: (size = 18) => Icons.svg(`
    <polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"></polygon>
    <line x1="9" y1="3" x2="9" y2="18"></line>
    <line x1="15" y1="6" x2="15" y2="21"></line>
  `, size),

  layers: (size = 16) => Icons.svg(`
    <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
    <polyline points="2 17 12 22 22 17"></polyline>
    <polyline points="2 12 12 17 22 12"></polyline>
  `, size),

  clipboardList: (size = 18) => Icons.svg(`
    <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
    <path d="M12 11h4"></path>
    <path d="M12 16h4"></path>
    <path d="M8 11h.01"></path>
    <path d="M8 16h.01"></path>
  `, size),

  mapPin: (size = 18) => Icons.svg(`
    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
    <circle cx="12" cy="10" r="3"></circle>
  `, size),

  truck: (size = 18) => Icons.svg(`
    <rect x="1" y="3" width="15" height="13"></rect>
    <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
    <circle cx="5.5" cy="18.5" r="2.5"></circle>
    <circle cx="18.5" cy="18.5" r="2.5"></circle>
  `, size),

  settings: (size = 18) => Icons.svg(`
    <circle cx="12" cy="12" r="3"></circle>
    <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
  `, size),

  shieldCheck: (size = 18) => Icons.svg(`
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
    <path d="m9 12 2 2 4-4"></path>
  `, size),

  search: (size = 16) => Icons.svg(`
    <circle cx="11" cy="11" r="8"></circle>
    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
  `, size),

  filter: (size = 16) => Icons.svg(`
    <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"></polygon>
  `, size),

  download: (size = 16) => Icons.svg(`
    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
    <polyline points="7 10 12 15 17 10"></polyline>
    <line x1="12" y1="15" x2="12" y2="3"></line>
  `, size),

  plus: (size = 16) => Icons.svg(`
    <line x1="12" y1="5" x2="12" y2="19"></line>
    <line x1="5" y1="12" x2="19" y2="12"></line>
  `, size),

  edit: (size = 14) => Icons.svg(`
    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
  `, size),

  cloud: (size = 16) => Icons.svg(`
    <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"></path>
  `, size),

  activity: (size = 16) => Icons.svg(`
    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
  `, size),

  refresh: (size = 16) => Icons.svg(`
    <path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path>
    <path d="M3 3v5h5"></path>
    <path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"></path>
    <path d="M16 21h5v-5"></path>
  `, size),

  smartphone: (size = 18) => Icons.svg(`
    <rect width="14" height="20" x="5" y="2" rx="2" ry="2"></rect>
    <path d="M12 18h.01"></path>
  `, size),

  users: (size = 18) => Icons.svg(`
    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
    <circle cx="9" cy="7" r="4"></circle>
    <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
  `, size),

  userPlus: (size = 16) => Icons.svg(`
    <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
    <circle cx="8.5" cy="7" r="4"></circle>
    <line x1="20" y1="8" x2="20" y2="14"></line>
    <line x1="23" y1="11" x2="17" y2="11"></line>
  `, size),

  clipboardPlus: (size = 16) => Icons.svg(`
    <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
    <line x1="12" y1="11" x2="12" y2="17"></line>
    <line x1="9" y1="14" x2="15" y2="14"></line>
  `, size),

  eye: (size = 16) => Icons.svg(`
    <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"></path>
    <circle cx="12" cy="12" r="3"></circle>
  `, size),

  eyeOff: (size = 16) => Icons.svg(`
    <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"></path>
    <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"></path>
    <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"></path>
    <line x1="2" y1="2" x2="22" y2="22"></line>
  `, size),
  clipboardCheck: (size = 18) => Icons.svg(`
    <rect width="8" height="4" x="8" y="2" rx="1" ry="1"></rect>
    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
    <path d="m9 14 2 2 4-4"></path>
  `, size),

  briefcase: (size = 18) => Icons.svg(`
    <rect width="20" height="14" x="2" y="7" rx="2" ry="2"></rect>
    <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
  `, size),

  clipboard: (size = 18) => Icons.svg(`
    <rect width="8" height="4" x="8" y="2" rx="1" ry="1"></rect>
    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
  `, size),

  camera: (size = 18) => Icons.svg(`
    <path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"></path>
    <circle cx="12" cy="13" r="3"></circle>
  `, size),

  maximize: (size = 16) => Icons.svg(`
    <path d="M8 3H5a2 2 0 0 0-2 2v3"></path>
    <path d="M21 8V5a2 2 0 0 0-2-2h-3"></path>
    <path d="M3 16v3a2 2 0 0 0 2 2h3"></path>
    <path d="M16 21h3a2 2 0 0 0 2-2v-3"></path>
  `, size),

  shield: (size = 16) => Icons.svg(`
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
  `, size),

  x: (size = 16) => Icons.svg(`
    <line x1="18" y1="6" x2="6" y2="18"></line>
    <line x1="6" y1="6" x2="18" y2="18"></line>
  `, size)
};
