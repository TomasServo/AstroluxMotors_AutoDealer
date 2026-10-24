from pathlib import Path
import hashlib,re
p=Path(__file__).resolve().parents[1];main=p/'mods/PZ_TSB_AstroluxStructure';shim=p/'mods/PZ_TSB_AstroluxFourSidesTest'
assert not list(shim.rglob('*.lua')) and not list(shim.rglob('*.pack'))
info=(main/'42/mod.info').read_text();packs=re.findall(r'^pack=(.+)$',info,re.M);tiles=re.findall(r'^tiledef=(\S+) (\d+)$',info,re.M)
assert len(packs)==len(set(packs));assert len(tiles)==len(set(i for _,i in tiles))
for name in packs:assert (main/'42/media/texturepacks'/f'{name}.pack').exists(),name
for name,_ in tiles:assert (main/'42/media'/f'{name}.tiles').exists(),name
geo=(main/'common/media/tileGeometry.txt').read_text();assert geo.count('{')==geo.count('}')
names=re.findall(r'name\s*=\s*(\w+)',geo);assert len(names)==len(set(names))
assert 'TSBAstroluxDisplay' in names and 'TSBAstroluxBayTest' in names
print('PASS: main owns all registered assets; unique pack/tile IDs and geometry; legacy shim has no code/assets')
