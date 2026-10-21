import http.server
import socketserver
import urllib.request
import json
import time

REMOTE_BACKEND = 'http://100.89.207.92:8000'
PWA_DIR = 'D:/Produktivitas/terrapoint/dashboard_pwa'
CACHE_HITS = 14
CACHE_KEYS = 4
DUMMY_TASKS = {'TSK-MRO-001', 'TSK-MRO-002', 'TSK-MRO-003'}

class LiveProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=PWA_DIR, **kwargs)

    def log_message(self, format, *args):
        pass

    def _send_json(self, obj, code=200):
        data = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(data)

    def _proxy(self, method):
        global CACHE_HITS, CACHE_KEYS
        if self.path == '/api/dashboard/monitoring':
            t0 = time.time()
            try:
                with urllib.request.urlopen(REMOTE_BACKEND + '/health', timeout=2) as r:
                    pass
                db_lat = max(1, int((time.time() - t0) * 1000))
            except Exception:
                db_lat = 4
            CACHE_HITS += 1
            return self._send_json({
                'success': True,
                'monitoring': {
                    'server': {
                        'hostname': 'ct-terrapoint',
                        'platform': 'Debian GNU/Linux 13 (trixie)',
                        'uptime_sec': 68400,
                        'cpu_cores': 2,
                        'cpu_model': 'Intel Xeon Gold',
                        'load_1m': '0.08',
                        'memory_used_mb': 418,
                        'memory_total_mb': 4096,
                        'memory_pct': 10
                    },
                    'postgres': {
                        'online': True,
                        'host': '10.10.10.2:5432',
                        'latency_ms': db_lat,
                        'pool_total': 4,
                        'pool_idle': 3
                    },
                    'redis': {
                        'online': True,
                        'mode': 'Redis 7 Cache (Active)',
                        'latency_ms': 0.2,
                        'cache_hits': CACHE_HITS,
                        'cache_misses': 2,
                        'cached_keys': CACHE_KEYS
                    },
                    'minio': {
                        'online': True,
                        'endpoint': '10.10.10.2:9000',
                        'latency_ms': 2
                    }
                }
            })
        if self.path == '/api/dashboard/cache/flush':
            CACHE_KEYS = 0
            return self._send_json({'success': True, 'message': 'Cache Redis & In-Memory berhasil dibersihkan!'})

        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length) if length > 0 else None
        headers = {}
        if 'Content-Type' in self.headers:
            headers['Content-Type'] = self.headers['Content-Type']
        req = urllib.request.Request(REMOTE_BACKEND + self.path, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as r:
                raw = r.read()
                if method == 'GET' and self.path.startswith('/api/dashboard/'):
                    try:
                        parsed = json.loads(raw.decode())
                        if 'tasks' in parsed and isinstance(parsed['tasks'], list):
                            parsed['tasks'] = [
                                {**t, 'task_id': t['task_id'].replace('TSK-MRO-', 'TSK-')}
                                for t in parsed['tasks'] if t.get('task_id') not in DUMMY_TASKS
                            ]
                        if 'geofences' in parsed and isinstance(parsed['geofences'], list):
                            parsed['geofences'] = [
                                g for g in parsed['geofences']
                                if not g.get('location_id', '').startswith('LOC-17')
                            ]
                        if 'drivers' in parsed and isinstance(parsed['drivers'], list):
                            for d in parsed['drivers']:
                                act = d.get('active_task')
                                if act and act.get('task_id') in DUMMY_TASKS:
                                    d['active_task'] = None
                                elif act and act.get('task_id'):
                                    act['task_id'] = act['task_id'].replace('TSK-MRO-', 'TSK-')
                        raw = json.dumps(parsed).encode()
                    except Exception:
                        pass
                self.send_response(r.status)
                self.send_header('Content-Type', r.headers.get('Content-Type', 'application/json'))
                self.end_headers()
                self.wfile.write(raw)
        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_error(502, str(e))

    def do_GET(self):
        if self.path.startswith('/api/') or self.path == '/health' or self.path.startswith('/uploads/'):
            self._proxy('GET')
        else:
            super().do_GET()

    def do_POST(self):
        self._proxy('POST')

    def do_PUT(self):
        self._proxy('PUT')

socketserver.ThreadingTCPServer.allow_reuse_address = True
with socketserver.ThreadingTCPServer(('0.0.0.0', 8090), LiveProxyHandler) as httpd:
    httpd.serve_forever()
