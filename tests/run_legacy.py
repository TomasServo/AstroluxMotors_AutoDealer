"""Run each legacy Lua script in an isolated Lua 5.1 VM (pip install lupa)."""
from pathlib import Path
import os
import json
from lupa.lua51 import LuaRuntime
os.chdir(Path(__file__).resolve().parents[1])
results={}
for p in sorted(Path('tests').rglob('*.lua')):
    if p.name == 'cash-fixture.lua':
        continue  # Shared fixture exercised by the payment suites.
    vm=LuaRuntime()
    output=[]
    vm.globals().print=lambda *args: output.append(' '.join(map(str,args)))
    try:
        vm.execute('assert(loadfile(...))()',p.as_posix())
        assert any('PASS' in line for line in output), 'Missing completion marker'
        results[p.as_posix()]={'status':'pass','output':output}
    except Exception as exc:
        results[p.as_posix()]={'status':'fail','error':str(exc),'output':output}
        print('FAIL',p, str(exc).splitlines()[0])
Path('docs/LEGACY-TEST-RESULTS.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
failed=sum(r['status']=='fail' for r in results.values())
print(f'{len(results)-failed} passed; {failed} failed')
raise SystemExit(bool(failed))
