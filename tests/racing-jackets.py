"""Check native clothing registration and assets in the published jacket package."""
from pathlib import Path
import re,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
mod=root/'mods/PZ_TSB_AstroluxStructure'
entries=ET.parse(mod/'42/media/fileGuidTable.xml').findall('files')
registered={e.findtext('path'):e.findtext('guid') for e in entries}
script=(mod/'42/media/scripts/TSBAstroluxRacingOutfit.txt').read_text()
assert set(re.findall(r'\bitem (\w+)',script))=={'AstroluxRacingJacket','AstroluxRacingJacketWhite'}
for name in ('AstroluxRacingJacket','AstroluxRacingJacketWhite'):
    rel='media/clothing/clothingItems/'+name+'.xml'
    xml=ET.parse(mod/'42'/rel)
    assert registered[rel]==xml.findtext('m_GUID')
    for key in ('m_AllowRandomHue','m_AllowRandomTint'):assert xml.findtext(key)=='false'
    assert not xml.findall('m_DecalGroup')
    for key in ('m_MaleModel','m_FemaleModel'):
        model=(mod/'42'/xml.findtext(key)).read_text()
        assert model.startswith('xof 0303txt 0032')
        m=re.search(r'\n Mesh \w+ \{\s*(\d+);',model)
        assert m and int(m[1])==1920,'Published model is not the user-tested version'
        assert 'XSkinMeshHeader' in model and 'SkinWeights {' in model
    texture=mod/'common/media/textures'/(xml.findtext('textureChoices')+'.png')
    assert texture.read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
    icon=mod/('common/media/textures/Item_TSB_'+name+'.png')
    assert icon.read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
print('PASS: accepted jacket GUID registration, tested models, materials and icons')
