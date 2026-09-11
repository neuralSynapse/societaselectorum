from __future__ import annotations

import asyncio
import json
from pathlib import Path

from PIL import Image
from playwright.async_api import async_playwright

URL = "http://127.0.0.1:8787/index.html"
OUT = Path("/tmp/chronica-web")
SCREENSHOT = OUT / "web_visibility.png"
LOG = OUT / "browser_console.json"


async def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    console: list[dict[str, str]] = []

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1280, "height": 720})
        page.on("console", lambda msg: console.append({"type": msg.type, "text": msg.text}))
        page.on("pageerror", lambda err: console.append({"type": "pageerror", "text": str(err)}))

        await page.goto(URL, wait_until="domcontentloaded", timeout=60000)
        await page.wait_for_selector("canvas", state="visible", timeout=60000)
        await page.wait_for_timeout(5000)

        canvas = page.locator("canvas").first
        box = await canvas.bounding_box()
        if box is None:
            raise RuntimeError("Godot canvas has no bounding box")

        # CanonicalBootGate is rendered inside the Godot canvas. Its primary
        # NOVA CAMPANHA button is centered slightly below the vertical midpoint.
        await page.mouse.click(box["x"] + box["width"] * 0.5, box["y"] + box["height"] * 0.58)
        await page.wait_for_timeout(10000)

        await page.screenshot(path=str(SCREENSHOT))
        LOG.write_text(json.dumps(console, ensure_ascii=False, indent=2), encoding="utf-8")
        await browser.close()

    image = Image.open(SCREENSHOT).convert("RGB")
    width, height = image.size
    crop = image.crop((int(width * 0.15), int(height * 0.18), int(width * 0.85), int(height * 0.72)))
    pixels = list(crop.getdata())
    if not pixels:
        raise RuntimeError("browser probe crop is empty")

    luminance = [
        (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
        for r, g, b in pixels
    ]
    mean_luminance = sum(luminance) / len(luminance)
    visible_ratio = sum(1 for value in luminance if value > 0.02) / len(luminance)

    print(
        "WEB_GAMEPLAY_VISIBILITY mean_luminance=%.4f visible_ratio=%.4f screenshot=%s"
        % (mean_luminance, visible_ratio, SCREENSHOT)
    )

    # The real working native boot is ~0.061 mean luminance and ~0.99 visible
    # ratio in this same crop. The reported browser regression is ~0.004 and
    # effectively 0 visible ratio. Keep generous margins for GPU differences.
    if mean_luminance < 0.020 or visible_ratio < 0.35:
        print("WEB_GAMEPLAY_VISIBILITY=FAIL")
        return 2

    print("WEB_GAMEPLAY_VISIBILITY=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
