"""Render code-defined lettering into two native isometric entrance-sign sprites."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import io,struct
root=Path(__file__).resolve().parents[1]
media=root/'mods/PZ_TSB_AstroluxStructure/42/media'
art=root/'artwork';art.mkdir(exist_ok=True)
art.joinpath('entrance-sign.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="64" viewBox="0 0 256 64">
<rect x="1" y="1" width="254" height="62" rx="3" fill="#101c29" stroke="#45d8ff" stroke-width="2"/>
<text x="128" y="32" text-anchor="middle" font-family="Arial" font-style="italic" font-weight="bold" font-size="32" fill="#9deaff">ASTROLUX</text>
<text x="128" y="54" text-anchor="middle" font-family="Arial" font-weight="bold" font-size="16" fill="#e9c35e">MOTORS</text></svg>''')
panel=Image.new('RGBA',(256,64));d=ImageDraw.Draw(panel)
d.rounded_rectangle((1,1,254,62),3,fill='#101c29',outline='#45d8ff',width=2)
fontroot=Path('C:/Windows/Fonts')
d.text((128,31),'ASTROLUX',font=ImageFont.truetype(str(fontroot/'arialbi.ttf'),32),anchor='ms',fill='#9deaff')
d.text((128,54),'MOTORS',font=ImageFont.truetype(str(fontroot/'arialbd.ttf'),16),anchor='ms',fill='#e9c35e')
panel.save(art/'entrance-sign-front.png')
faces=[panel.transform((256,320),Image.Transform.AFFINE,(2,0,-256,-1,2,128),Image.Resampling.BICUBIC),
       panel.transform((256,320),Image.Transform.AFFINE,(2,0,0,1,2,-128),Image.Resampling.BICUBIC)]
pack=io.BytesIO();pack.write(b'PZPK'+struct.pack('<ii',1,2))
def string(s):b=s.encode();pack.write(struct.pack('<i',len(b))+b)
for i,face in enumerate(faces):
    face.save(art/f'entrance-sign-{i}.png');png=io.BytesIO();face.save(png,format='PNG');data=png.getvalue()
    string(f'TSBAstroluxEntranceSignPage{i}');pack.write(struct.pack('<ii',1,1))
    string(f'TSBAstroluxEntranceSign_{i}');pack.write(struct.pack('<8i',0,0,256,320,-64,-32,256,320))
    pack.write(struct.pack('<i',len(data))+data)
(media/'texturepacks/TSBAstroluxEntranceSign.pack').write_bytes(pack.getvalue())
tile=io.BytesIO();tile.write(b'tdef'+struct.pack('<ii',1,1))
tile.write(b'TSBAstroluxEntranceSign\nTSBAstroluxEntranceSign.png\n'+struct.pack('<iiii',2,1,1,2))
for facing in ['S','E']:
    props={'CustomName':'Astrolux Motors Sign','Facing':facing}
    tile.write(struct.pack('<i',len(props)))
    for k,v in props.items():tile.write((k+'\n'+v+'\n').encode())
(media/'TSBAstroluxEntranceSign.tiles').write_bytes(tile.getvalue())
print('Built two non-colliding entrance signs; existing artwork unchanged.')
