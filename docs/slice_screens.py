import asyncio
import os
import threading
import http.server
import socketserver
from playwright.async_api import async_playwright

OUTPUT_DIR = 'D:/Produktivitas/terrapoint/docs/flow-assets'
os.makedirs(OUTPUT_DIR, exist_ok=True)

class HandlerWithDir(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

def start_server(port, directory):
    handler = lambda *args, **kwargs: HandlerWithDir(*args, directory=directory, **kwargs)
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        httpd.serve_forever()

async def slice_screens():
    t = threading.Thread(target=start_server, args=(8112, 'D:/Produktivitas/terrapoint/designs'), daemon=True)
    t.start()
    await asyncio.sleep(0.8)

    async with async_playwright() as p:
        browser = await p.chromium.launch(channel="msedge", headless=True)
        context = await browser.new_context(viewport={"width": 2400, "height": 2200}, device_scale_factor=2)
        page = await context.new_page()
        await page.goto("http://127.0.0.1:8112/pen2_artboard.html")
        await asyncio.sleep(2.0)

        screens = await page.locator('.phone-screen').all()
        print(f"Found {len(screens)} phone screens in pen2_artboard.html")

        screen_names = [
            "mob-new-01-login.png",
            "mob-new-02-dashboard.png",
            "mob-new-03-hauling.png",
            "mob-new-04-foto-muatan.png",
            "mob-new-05-foto-dumping.png",
            "mob-new-06-selesai.png",
            "mob-new-07-riwayat.png",
            "mob-new-08-radar.png",
            "mob-new-09-lapor.png",
            "mob-new-10-bantuan.png"
        ]

        for idx, s in enumerate(screens):
            if idx < len(screen_names):
                out_p = os.path.join(OUTPUT_DIR, screen_names[idx])
                await s.screenshot(path=out_p)
                print(f"Saved: {screen_names[idx]}")

        await context.close()
        await browser.close()
        print("All 10 screen individual PNGs saved to docs/flow-assets/!")

if __name__ == "__main__":
    asyncio.run(slice_screens())
