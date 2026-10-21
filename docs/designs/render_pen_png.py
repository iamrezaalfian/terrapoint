import asyncio
import os
import threading
import http.server
import socketserver
from PIL import Image
from playwright.async_api import async_playwright

PNG_DIR = 'D:/Produktivitas/terrapoint/designs/png'
os.makedirs(PNG_DIR, exist_ok=True)

class HandlerWithDir(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

def start_server(port, directory):
    handler = lambda *args, **kwargs: HandlerWithDir(*args, directory=directory, **kwargs)
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        httpd.serve_forever()

async def render_all_pngs():
    # Start thread server on port 8095
    t = threading.Thread(target=start_server, args=(8095, 'D:/Produktivitas/terrapoint/designs'), daemon=True)
    t.start()
    await asyncio.sleep(0.8)

    async with async_playwright() as p:
        browser = await p.chromium.launch(channel="msedge", headless=True)
        context = await browser.new_context(viewport={"width": 1280, "height": 1000}, device_scale_factor=2)
        page = await context.new_page()
        await page.goto("http://127.0.0.1:8095/index.html")
        await asyncio.sleep(1.2)

        phone_locator = page.locator('.phone-canvas')

        screens = [
            ("01_login", 0),
            ("02_quick_pin", 1),
            ("03_home_autodetect", 2),
            ("04_viewfinder_50m", 3),
            ("05_preview_watermark", 4),
            ("06_hauling_active", 5),
            ("07_sync_queue", 6)
        ]

        rendered_files_dark = []
        rendered_files_light = []

        # 1. Render 7 Dark Mode Screens
        await page.evaluate("setTheme('dark');")
        await asyncio.sleep(0.3)
        for name, idx in screens:
            await page.evaluate(f"document.querySelector('select').selectedIndex = {idx}; document.querySelector('select').dispatchEvent(new Event('change'));")
            await asyncio.sleep(0.3)
            out_path = os.path.join(PNG_DIR, f"{name}_dark.png")
            await phone_locator.screenshot(path=out_path)
            rendered_files_dark.append(out_path)
            print(f"Rendered {out_path}")

        # 2. Render 7 Light Mode Screens
        await page.evaluate("setTheme('light');")
        await asyncio.sleep(0.3)
        for name, idx in screens:
            await page.evaluate(f"document.querySelector('select').selectedIndex = {idx}; document.querySelector('select').dispatchEvent(new Event('change'));")
            await asyncio.sleep(0.3)
            out_path = os.path.join(PNG_DIR, f"{name}_light.png")
            await phone_locator.screenshot(path=out_path)
            rendered_files_light.append(out_path)
            print(f"Rendered {out_path}")

        await context.close()
        await browser.close()

    # 3. Create Master Artboard Composite (All 14 Frames on 1 Canvas)
    print("Creating Master Artboard Composite Image...")
    card_w, card_h = 380 * 2, 810 * 2  # 760 x 1620
    gap = 40
    padding = 60

    # 7 columns, 2 rows (Dark on Top, Light on Bottom)
    total_w = (padding * 2) + (7 * card_w) + (6 * gap)
    total_h = (padding * 2) + (2 * card_h) + gap + 100 # header space

    artboard = Image.new("RGB", (total_w, total_h), color=(10, 13, 20))

    # Paste Dark Mode row
    for col_idx, fpath in enumerate(rendered_files_dark):
        im = Image.open(fpath)
        x = padding + (col_idx * (card_w + gap))
        y = padding + 80
        artboard.paste(im, (x, y))

    # Paste Light Mode row
    for col_idx, fpath in enumerate(rendered_files_light):
        im = Image.open(fpath)
        x = padding + (col_idx * (card_w + gap))
        y = padding + 80 + card_h + gap
        artboard.paste(im, (x, y))

    composite_path = os.path.join(PNG_DIR, "terrapoint_mobile_ui_all_14_frames.png")
    artboard.save(composite_path, quality=95)
    print(f"Master Artboard Canvas created: {composite_path} ({total_w}x{total_h})")

if __name__ == "__main__":
    asyncio.run(render_all_pngs())
