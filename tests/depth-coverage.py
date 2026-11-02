"""Check native loader registration and shader coverage against the actual atlas.

Run with Python and Pillow. No game or runtime files are modified.
"""
from pathlib import Path
import hashlib
import io
import re
import struct
from PIL import Image

root = Path(__file__).resolve().parents[1] / 'mods/PZ_TSB_AstroluxStructure'
pack = (root / '42/media/texturepacks/TSBAstroluxDisplay.pack').read_bytes()
assert hashlib.sha256(pack).hexdigest() == '65e6220d8153ec884f3f3aea9dfa79707d38e9aeddf56a7636afa975e6b8f9af'
stream = io.BytesIO(pack)
integer = lambda: struct.unpack('<i', stream.read(4))[0]
def string():
    return stream.read(integer()).decode()
assert stream.read(4) == b'PZPK' and integer() == 1 and integer() == 1
string()
count, flags = integer(), integer()
entries = [(string(), struct.unpack('<8i', stream.read(32))) for _ in range(count)]
art = Image.open(io.BytesIO(stream.read(integer()))).convert('RGBA')
assert count == 404 and not stream.read()

# Native mod registration checks common/media/tileGeometry.txt before reading
# its depthmaps directory. Native tileset addressing is eight columns.
media = root / 'common/media'
geometry = (media / 'tileGeometry.txt').read_text()
assert 'VERSION = 2' in geometry and 'name = TSBAstroluxDisplay,' in geometry
slots = [(int(x), int(y)) for x, y in re.findall(r'xy = (\d+)x(\d+),', geometry)]
assert slots == [(i % 8, i // 8) for i in range(404)]
depth = Image.open(media / 'depthmaps/DEPTH_TSBAstroluxDisplay.png').convert('RGBA')
assert depth.size == (1024, 13056)
visible = 0
for name, (x, y, w, h, ox, oy, fw, fh) in entries:
    i = int(name.rsplit('_', 1)[1])
    assert (fw, fh) == (128, 256)
    mask = art.crop((x, y, x + w, y + h)).getchannel('A')
    left, top = (i % 8) * 128 + ox, (i // 8) * 256 + oy
    samples = depth.crop((left, top, left + w, top + h)).getchannel('R')
    for alpha, value in zip(mask.getdata(), samples.getdata()):
        if alpha:
            visible += 1
            assert value > 0, f'Native shader would discard {name}'
assert visible == 1446044
assert depth.crop((512, 12800, 1024, 13056)).getbbox() is None
print('PASS: loader registration, 404 native slots, zero discarded artwork pixels; approved pack unchanged')
