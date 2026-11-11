#!/usr/bin/env python3
"""Render docs/sample-report.html with Playwright and save a screenshot of the top of the report
(header, summary and the first findings), which keeps the image a readable size for the README.

Usage: python tools/capture_screenshot.py [html_path] [png_path]
Requires: pip install playwright && playwright install chromium
"""
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

root = Path(__file__).resolve().parent.parent
html = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "docs" / "sample-report.html"
png = Path(sys.argv[2]) if len(sys.argv) > 2 else root / "docs" / "sample-report.png"

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1100, "height": 900}, device_scale_factor=1)
    page.emulate_media(color_scheme="light")
    page.goto(html.resolve().as_uri())
    page.screenshot(path=str(png), full_page=True, clip={"x": 0, "y": 0, "width": 1100, "height": 1560})
    browser.close()
print(f"Wrote {png}")
