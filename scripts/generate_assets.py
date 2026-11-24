"""Generate the app icon with the Python standard library; no third-party packages."""
from pathlib import Path
import json
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'CollageApp' / 'Assets.xcassets'
ICON = ASSETS / 'AppIcon.appiconset'


def inside_round_rect(x, y, left, top, right, bottom, radius):
    dx = max(left + radius - x, 0, x - (right - radius))
    dy = max(top + radius - y, 0, y - (bottom - radius))
    return left <= x <= right and top <= y <= bottom and dx * dx + dy * dy <= radius * radius


def icon_png():
    size = 1024
    rows = bytearray()
    for y in range(size):
        rows.append(0)
        for x in range(size):
            t = (x + y) / (2 * size)
            color = (int(255 - t * 16), int(79 - t * 30), int(126 - t * 16))
            if inside_round_rect(x, y, 190, 168, 834, 856, 72):
                color = (255, 250, 251)
            if inside_round_rect(x, y, 228, 206, 796, 576, 26):
                color = (251, 132, 165)
            if inside_round_rect(x, y, 228, 608, 496, 818, 26):
                color = (244, 189, 207)
            if inside_round_rect(x, y, 528, 608, 796, 818, 26):
                color = (209, 194, 233)
            rows.extend(color)

    def chunk(kind, payload):
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload) & 0xffffffff)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))


if __name__ == '__main__':
    ICON.mkdir(parents=True, exist_ok=True)
    (ASSETS / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}))
    (ICON / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}],
        'info': {'author': 'xcode', 'version': 1}
    }))
    (ICON / 'AppIcon.png').write_bytes(icon_png())
    print('Generated 1024px Pintu app icon')
