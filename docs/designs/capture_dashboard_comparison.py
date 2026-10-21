import os
import asyncio
import threading
import http.server
import socketserver
from playwright.async_api import async_playwright

OUTPUT_DIR = 'D:/Produktivitas/terrapoint/designs/comparison'
os.makedirs(OUTPUT_DIR, exist_ok=True)

class HandlerWithDir(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

def start_server(port, directory):
    handler = lambda *args, **kwargs: HandlerWithDir(*args, directory=directory, **kwargs)
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        httpd.serve_forever()

async def capture_both():
    t = threading.Thread(target=start_server, args=(8120, 'D:/Produktivitas/terrapoint/dashboard_pwa'), daemon=True)
    t.start()
    await asyncio.sleep(0.8)

    async with async_playwright() as p:
        browser = await p.chromium.launch(channel="msedge", headless=True)

        # 1. Capture Existing Dashboard (Dark Command Center)
        context1 = await browser.new_context(viewport={"width": 1440, "height": 900}, device_scale_factor=1.5)
        page1 = await context1.new_page()
        await page1.goto("http://127.0.0.1:8120/index.html")
        await page1.evaluate("localStorage.setItem('terrapoint_theme', 'DARK'); document.body.classList.remove('light-theme');")
        await page1.reload()
        await asyncio.sleep(1.8)
        existing_path = os.path.join(OUTPUT_DIR, "dashboard_01_existing_dark.png")
        await page1.screenshot(path=existing_path)
        print("Captured Existing Dark Dashboard!")
        await context1.close()

        # 2. Capture Clean Modern Tech Dashboard (Light Theme with Slate, Deep Navy & Precision Amber)
        context2 = await browser.new_context(viewport={"width": 1440, "height": 900}, device_scale_factor=1.5)
        page2 = await context2.new_page()
        await page2.goto("http://127.0.0.1:8120/index.html")
        await page2.evaluate("localStorage.setItem('terrapoint_theme', 'LIGHT'); document.body.classList.add('light-theme');")
        await page2.reload()
        await asyncio.sleep(1.8)
        planning_path = os.path.join(OUTPUT_DIR, "dashboard_02_planning_clean_tech.png")
        await page2.screenshot(path=planning_path)
        print("Captured Planning Clean Modern Tech Dashboard!")
        await context2.close()

        await browser.close()

if __name__ == "__main__":
    asyncio.run(capture_both())
