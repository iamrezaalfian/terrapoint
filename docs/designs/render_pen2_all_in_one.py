import asyncio
import os
import threading
import http.server
import socketserver
from playwright.async_api import async_playwright

OUTPUT_PNG = 'D:/Produktivitas/terrapoint/designs/png/terrapoint_mobile_ui2_all_in_one.png'
PNG_DIR = 'D:/Produktivitas/terrapoint/designs/png'
os.makedirs(PNG_DIR, exist_ok=True)

class HandlerWithDir(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

def start_server(port, directory):
    handler = lambda *args, **kwargs: HandlerWithDir(*args, directory=directory, **kwargs)
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        httpd.serve_forever()

async def capture_png():
    t = threading.Thread(target=start_server, args=(8109, 'D:/Produktivitas/terrapoint/designs'), daemon=True)
    t.start()
    await asyncio.sleep(0.8)

    async with async_playwright() as p:
        browser = await p.chromium.launch(channel="msedge", headless=True)
        context = await browser.new_context(viewport={"width": 2400, "height": 2200}, device_scale_factor=2)
        page = await context.new_page()
        await page.goto("http://127.0.0.1:8109/pen2_artboard.html")
        await asyncio.sleep(2.0)

        # Full page screenshot of the clean unified artboard
        await page.screenshot(path=OUTPUT_PNG, full_page=True)
        await context.close()
        await browser.close()
        print(f"Master All-in-One PNG rendered with complete Mining Safety Amber palette: {OUTPUT_PNG}")

if __name__ == "__main__":
    asyncio.run(capture_png())
