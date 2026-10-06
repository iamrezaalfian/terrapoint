import asyncio
import os
import threading
import http.server
import socketserver
from playwright.async_api import async_playwright

ASSETS_DIR = 'D:/Produktivitas/terrapoint/docs/flow-assets'
os.makedirs(ASSETS_DIR, exist_ok=True)

class HandlerWithDir(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

def start_server(port, directory):
    handler = lambda *args, **kwargs: HandlerWithDir(*args, directory=directory, **kwargs)
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        httpd.serve_forever()

async def capture_all():
    # Start thread servers
    t1 = threading.Thread(target=start_server, args=(8091, 'D:/Produktivitas/terrapoint/designs'), daemon=True)
    t2 = threading.Thread(target=start_server, args=(8092, 'D:/Produktivitas/terrapoint/dashboard_pwa'), daemon=True)
    t1.start()
    t2.start()
    await asyncio.sleep(1.0)

    async with async_playwright() as p:
        browser = await p.chromium.launch(channel="msedge", headless=True)

        # 1. CAPTURE MOBILE APP SCREENS (Target ONLY .phone-canvas)
        mobile_context = await browser.new_context(viewport={"width": 1280, "height": 1000}, device_scale_factor=2)
        mobile_page = await mobile_context.new_page()
        await mobile_page.goto("http://127.0.0.1:8091/index.html")
        await asyncio.sleep(1.5)

        phone_locator = mobile_page.locator('.phone-canvas')

        # Screen 1: Login
        await mobile_page.evaluate("document.querySelector('select').selectedIndex = 0; document.querySelector('select').dispatchEvent(new Event('change'));")
        await asyncio.sleep(0.4)
        await phone_locator.screenshot(path=os.path.join(ASSETS_DIR, "mobile-01-login.png"))

        # Screen 2: PIN Unlock
        await mobile_page.evaluate("document.querySelector('select').selectedIndex = 1; document.querySelector('select').dispatchEvent(new Event('change'));")
        await asyncio.sleep(0.4)
        await phone_locator.screenshot(path=os.path.join(ASSETS_DIR, "mobile-02-pin.png"))

        # Screen 3: Home Auto-Detect
        await mobile_page.evaluate("document.querySelector('select').selectedIndex = 2; document.querySelector('select').dispatchEvent(new Event('change'));")
        await asyncio.sleep(0.4)
        await phone_locator.screenshot(path=os.path.join(ASSETS_DIR, "mobile-03-home.png"))

        # Screen 4: Viewfinder
        await mobile_page.evaluate("document.querySelector('select').selectedIndex = 3; document.querySelector('select').dispatchEvent(new Event('change'));")
        await asyncio.sleep(0.4)
        await phone_locator.screenshot(path=os.path.join(ASSETS_DIR, "mobile-04-viewfinder.png"))

        # Screen 5: Surveyor Watermark Preview
        await mobile_page.evaluate("document.querySelector('select').selectedIndex = 4; document.querySelector('select').dispatchEvent(new Event('change'));")
        await asyncio.sleep(0.4)
        await phone_locator.screenshot(path=os.path.join(ASSETS_DIR, "mobile-05-watermark.png"))

        # Screen 6: Hauling Active
        await mobile_page.evaluate("document.querySelector('select').selectedIndex = 5; document.querySelector('select').dispatchEvent(new Event('change'));")
        await asyncio.sleep(0.4)
        await phone_locator.screenshot(path=os.path.join(ASSETS_DIR, "mobile-06-hauling.png"))

        # Screen 7: Sync Queue
        await mobile_page.evaluate("document.querySelector('select').selectedIndex = 6; document.querySelector('select').dispatchEvent(new Event('change'));")
        await asyncio.sleep(0.4)
        await phone_locator.screenshot(path=os.path.join(ASSETS_DIR, "mobile-07-sync.png"))

        await mobile_context.close()
        print("Mobile .phone-canvas screenshots captured!")

        # 2. CAPTURE WEB DASHBOARD SCREENS (Target full window 1440x900)
        web_context = await browser.new_context(viewport={"width": 1440, "height": 900}, device_scale_factor=2)
        web_page = await web_context.new_page()
        await web_page.goto("http://127.0.0.1:8092/index.html")
        await asyncio.sleep(2.0)

        # Web 1: Satellite Map & Haul Roads
        await web_page.screenshot(path=os.path.join(ASSETS_DIR, "web-01-satellite-map.png"))

        # Web 2: Telemetry HUD Inspector (click DT-104)
        await web_page.evaluate("const c = document.querySelector('.fleet-card[data-unit=\"DT-104\"]'); if (c) c.click();")
        await asyncio.sleep(0.6)
        await web_page.screenshot(path=os.path.join(ASSETS_DIR, "web-02-telemetry-hud.png"))

        # Web 3: Trip Logs Table
        await web_page.evaluate("document.querySelector('.nav-item[data-page=\"page-trip-logs\"]').click();")
        await asyncio.sleep(0.5)
        await web_page.screenshot(path=os.path.join(ASSETS_DIR, "web-03-trip-logs.png"))

        # Web 4: Evidence Modal
        await web_page.evaluate("const b = document.querySelector('.btn-view-evidence'); if (b) b.click();")
        await asyncio.sleep(0.6)
        await web_page.screenshot(path=os.path.join(ASSETS_DIR, "web-04-evidence-modal.png"))
        await web_page.evaluate("const cl = document.getElementById('modal-close-btn'); if (cl) cl.click();")
        await asyncio.sleep(0.3)

        # Web 5: Master Geofence Checkpoints
        await web_page.evaluate("document.querySelector('.nav-item[data-page=\"page-geofence\"]').click();")
        await asyncio.sleep(0.5)
        await web_page.screenshot(path=os.path.join(ASSETS_DIR, "web-05-geofence.png"))

        # Web 6: Fleet Management Cards
        await web_page.evaluate("document.querySelector('.nav-item[data-page=\"page-fleet\"]').click();")
        await asyncio.sleep(0.5)
        await web_page.screenshot(path=os.path.join(ASSETS_DIR, "web-06-fleet.png"))

        # Web 7: Dedicated Login Page
        await web_page.evaluate("document.getElementById('btn-user-profile').click();")
        await asyncio.sleep(0.3)
        await web_page.evaluate("document.getElementById('btn-dropdown-logout').click();")
        await asyncio.sleep(0.6)
        await web_page.screenshot(path=os.path.join(ASSETS_DIR, "web-07-login.png"))

        await web_context.close()
        await browser.close()
        print("Web screenshots captured successfully!")

if __name__ == "__main__":
    asyncio.run(capture_all())
