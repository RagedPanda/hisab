#!/usr/bin/env python3
"""Draws a phone body around each README screenshot so the gallery looks like
real devices: a Pixel style body (flat sides, punch-hole camera) for Android
and an iPhone 17 style body (thin bezels, round corners) for iOS.

Usage: tool/frame_screenshots.py android|ios <in-dir> <out-dir>
Needs Pillow (`python3 -m pip install Pillow`).
"""
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

# Everything is drawn this many times larger and scaled down, for smooth edges.
SUPERSAMPLE = 4
# Room around the body for the side buttons, in screenshot pixels.
BUTTON_ROOM = 4


@dataclass(frozen=True)
class Button:
    """A side button: which side, its top edge and length, in screenshot pixels."""
    side: str
    top: int
    length: int


@dataclass(frozen=True)
class DeviceBody:
    bezel: int
    screen_radius: int
    body_radius: int
    body_color: str
    rim_color: str
    rim_width: float
    buttons: tuple
    # Punch-hole camera (centre y below the screen top, diameter), or None
    # when the screenshot already shows the camera (iOS Dynamic Island).
    camera: tuple | None


PIXEL = DeviceBody(
    bezel=12, screen_radius=30, body_radius=42,
    body_color='#1f2023', rim_color='#5f6368', rim_width=2,
    buttons=(Button('right', 150, 44), Button('right', 220, 90)),
    camera=(22, 11),
)

IPHONE_17 = DeviceBody(
    bezel=11, screen_radius=50, body_radius=61,
    body_color='#16171a', rim_color='#8e9096', rim_width=2.5,
    buttons=(Button('left', 120, 26), Button('left', 175, 52), Button('left', 240, 52), Button('right', 190, 84)),
    camera=None,
)

DEVICES = {'android': PIXEL, 'ios': IPHONE_17}


def scaled(value: float) -> int:
    return round(value * SUPERSAMPLE)


def rounded_mask(size: tuple, radius: int) -> Image.Image:
    """An antialiased mask of a rounded rectangle, at screenshot scale."""
    big = Image.new('L', (size[0] * SUPERSAMPLE, size[1] * SUPERSAMPLE), 0)
    ImageDraw.Draw(big).rounded_rectangle((0, 0, big.width - 1, big.height - 1), scaled(radius), fill=255)
    return big.resize(size, Image.LANCZOS)


def button_box(button: Button, body_box: tuple) -> tuple:
    left, top, right, _ = body_box
    y0, y1 = top + scaled(button.top), top + scaled(button.top + button.length)
    if button.side == 'left':
        return (left - scaled(3), y0, left + scaled(4), y1)
    return (right - scaled(4), y0, right + scaled(3), y1)


def draw_body(screen_size: tuple, device: DeviceBody) -> Image.Image:
    """The phone body with an empty screen opening, drawn large."""
    width = screen_size[0] + 2 * (device.bezel + BUTTON_ROOM)
    height = screen_size[1] + 2 * (device.bezel + BUTTON_ROOM)
    canvas = Image.new('RGBA', (scaled(width), scaled(height)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    body_box = (scaled(BUTTON_ROOM), scaled(BUTTON_ROOM), canvas.width - scaled(BUTTON_ROOM) - 1, canvas.height - scaled(BUTTON_ROOM) - 1)
    for button in device.buttons:
        draw.rounded_rectangle(button_box(button, body_box), scaled(1.5), fill=device.rim_color)
    draw.rounded_rectangle(body_box, scaled(device.body_radius), fill=device.rim_color)
    inset = scaled(device.rim_width)
    inner_box = (body_box[0] + inset, body_box[1] + inset, body_box[2] - inset, body_box[3] - inset)
    draw.rounded_rectangle(inner_box, scaled(device.body_radius - device.rim_width), fill=device.body_color)
    return canvas.resize((width, height), Image.LANCZOS)


def draw_camera(framed: Image.Image, device: DeviceBody, screen_origin: int) -> None:
    if device.camera is None:
        return
    centre_y, diameter = device.camera
    size = scaled(diameter)
    dot = Image.new('L', (size, size), 0)
    ImageDraw.Draw(dot).ellipse((0, 0, size - 1, size - 1), fill=255)
    dot = dot.resize((diameter, diameter), Image.LANCZOS)
    left = (framed.width - diameter) // 2
    top = screen_origin + centre_y - diameter // 2
    framed.paste((8, 8, 10, 255), (left, top), dot)


def frame(screen: Image.Image, device: DeviceBody) -> Image.Image:
    """[screen] inside a drawn [device] body, on a transparent background."""
    framed = draw_body(screen.size, device)
    origin = BUTTON_ROOM + device.bezel
    framed.paste(screen.convert('RGBA'), (origin, origin), rounded_mask(screen.size, device.screen_radius))
    draw_camera(framed, device, origin)
    return framed


def main(argv: list) -> int:
    if len(argv) != 4 or argv[1] not in DEVICES:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    device, in_dir, out_dir = DEVICES[argv[1]], Path(argv[2]), Path(argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)
    for shot in sorted(in_dir.glob('[0-9]*.png')):
        frame(Image.open(shot), device).save(out_dir / shot.name, optimize=True)
        print(f'framed {out_dir / shot.name}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
